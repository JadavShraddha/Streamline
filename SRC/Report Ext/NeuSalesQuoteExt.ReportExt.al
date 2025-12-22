reportextension 50102 "Neu Sales Quote Ext" extends NeuSalesQuote
{

    dataset
    {
        add(Header)
        {
            column(Sell_to_Contact;"Sell-to Contact"){}
            column(SalespersonPurchaser_Email; SalespersonPurchaser."E-Mail") { }   
            column(SalespersonPurchaser_PhoneNo;SalespersonPurchaser."Phone No."){}
            column(Currency_Symbol; CurrencySymbol) { }
            column(Bill_to_Contact; SalespersonPurchaser.Name) { }
            column(CurrDate; CurrentDateTime()) { }
            column(Sell_to_Customer_Name;"Sell-to Customer Name"){}
            column(Sell_to_Address;"Sell-to Address"){}
            column(Sell_to_Address_2;"Sell-to Address 2"){}
            column(Sell_to_City;"Sell-to City"){}
            column(Sell_to_Post_Code;"Sell-to Post Code"){}
            column(Sell_to_Country_Region_Code;"Sell-to Country/Region Code"){}
            column(Company_Name; MyCompanyInfo."Ship-to Name") { }
            column(Company_Address; MyCompanyInfo."Ship-to Address") { }
            column(Company_Address_2; MyCompanyInfo."Ship-to Address 2") { }
            column(Company_City; MyCompanyInfo."Ship-to City") { }
            column(Company_Postcode; MyCompanyInfo."Ship-to Post Code") { }
            column(Company_Phone_No; MyCompanyInfo."Phone No.") { }
        }

        modify(Header)
        {
            trigger OnAfterAfterGetRecord()
            var
                GLS: Record "General Ledger Setup";
                Currency: Record Currency;
                Contact: Record Contact;
            begin
                if Header."Currency Code" = '' then begin
                    if GLS.Get() then
                        CurrencySymbol := GLS."Local Currency Symbol";
                end
                else
                    if Currency.Get(Header."Currency Code") then
                        CurrencySymbol := Currency.Symbol;

                Clear(Contact);
                Clear(SellToContactEmail);
                if Contact.Get("Sell-to Contact No.") then
                    SellToContactEmail := Contact."E-Mail";
            end;
        }

        add(Line)
        {
            column(Item_Picture; Item.Picture) { }
            column(WebDescription; WebDescription) { }
            column(GoodsTotal; GoodsTotal) { }
        }
        modify(Line)
        {
            trigger OnAfterPreDataItem()
            begin
                Line.SetFilter(Type, '%1', Type::Item);
                LastItem := '';
            end;

            trigger OnAfterAfterGetRecord()
            begin
                if LastItem = Line."No." then
                    CurrReport.Skip();

                LastItem := Line."No.";

                GoodsTotal := 0;
                GoodsTotal := Line."Line Amount";

                Clear(Item);
                Clear(WebDescription);
                If Line.Type = Line.Type::Item then
                    if Item.Get(Line."No.") then 
                        WebDescription := Item."Web Description";
            end;
        }

        addfirst(Line)
        {
            dataitem("NEU Item Builder Header"; "NEU Item Builder Header")
            {
                DataItemLinkReference = Line;
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("Document No."), "Line No." = field("Line No.");

                column(IS_Document_No_; "Document No.") { }
                dataitem(Item_Specification; "NEU Item Specifications")
                {
                    column(IS_Item_Category_Code; "Item Category Code") { }
                    column(Item_Specification_Code; "Item Specification Code") { }
                    column(Item_Specification_Text; "Item Specification Text") { }
                    column(Comments; Comments) { }
                    column(Sales_Comments; "Sales Comments") { }
                    column(IS_Line_No_; "Line No.") { }
                    column(IS_Document_Line_No_; "Document Line No.") { }

                    trigger OnPreDataItem()
                    begin
                        Item_Specification.SetRange("Sales Comments", True);
                        Item_Specification.SetRange("Document Type", "NEU Item Builder Header"."Document Type");
                        Item_Specification.SetRange("Document No.", "NEU Item Builder Header"."Document No.");
                        Item_Specification.SetRange("Document Line No.", "NEU Item Builder Header"."Line No.");
                        Item_Specification.SetRange("Item Category Code", "NEU Item Builder Header"."Item Category");
                    end;
                }
            }
           
            dataitem("Sales Line"; "Sales Line")
            {
                column(No_; "No.") { }
                column(Line_No_; "Line No.") { }
                column(Sales_Line_Type;Type){}
                column(Comment_Description; Description) { }
                column(Quantity; Quantity) { }
                column(Line_Amount; "Line Amount") { }

                trigger OnAfterGetRecord()
                begin
                    GoodsTotal += "Line Amount";
                end;

                trigger OnPreDataItem()
                begin
                    "Sales Line".SetRange("Document Type", SalesLine."Document Type"::Quote);
                    "Sales Line".SetRange("Document No.", Header."No.");
                    "Sales Line".SetFilter(Type, '%1|%2|%3|%4', Type::"Allocation Account", Type::"Charge (Item)", Type::"Fixed Asset", Type::Resource);
                    "Sales Line".SetFilter("Line No.", '%1..%2', Line."Line No.", FindNextLineNo());
                end;
            }
            dataitem(PriceBreakdown_Integer; Integer)
            {
                column(Number; Number) { }
                column(Qty; QuantityList.Get(Number)) { }
                column(Price; PriceList.Get(Number)) { }
                column(Total; LineAmtList.Get(Number)) { }
                column(LineType;LineType.Get(Number)) {}
                column(CarriageAmt;CarriageAmtList.Get(Number)) {}
                // trigger OnPreDataItem()
                // var
                //     SL: Record "Sales Line";
                //     PreviousNo: Code[20];
                // begin
                //     Clear(SL);
                //     Clear(QuantityList);
                //     Clear(PriceList);
                //     Clear(LineAmtList);
                //     sl.SetRange("Document Type", SalesLine."Document Type"::Quote);
                //     sl.SetRange("Document No.", Header."No.");
                //     sl.SetFilter(Type, '%1|%2', sl.Type::Item, SL.Type::"G/L Account");
                //     sl.SetFilter("Line No.", '%1..', Line."Line No.");
                //     if sl.FindSet() then
                //         repeat
                //             if (SL."No." = Line."No.") or ((SL.Type = SL.Type::"G/L Account") And (PreviousNo = Line."No.")) then begin
                //                 if SL.Type = SL.Type::Item then begin
                //                     QuantityList.Add(Format(SL.Quantity));
                //                     PreviousNo := SL."No.";
                //                     LineType.Add(1);
                //                 end
                //                 else begin
                //                     QuantityList.Add(SL.Description);
                //                     LineType.Add(2);
                //                 end;
                                    
                //                 PriceList.Add(SL."Unit Price");
                //                 LineAmtList.Add(SL."Line Amount");
                //                 GoodsTotal := SL."Line Amount";
                //             end
                //             else 
                //                 break;
                //         until sl.Next() = 0;

                //     PriceBreakdown_Integer.SetRange(Number, 1, QuantityList.Count());
                // end;

                trigger OnPreDataItem()
                var
                    SL: Record "Sales Line";
                    PreviousItemNo: Code[20];
                    LastIndex: Integer;
                    NewAmt: Decimal;
                begin
                    Clear(SL);
                    Clear(QuantityList);
                    Clear(PriceList);
                    Clear(LineAmtList);
                    Clear(CarriageAmtList);
                    Clear(LineType);

                    SL.SetRange("Document Type", SalesLine."Document Type"::Quote);
                    SL.SetRange("Document No.", Header."No.");
                    SL.SetFilter(Type, '%1|%2', SL.Type::Item, SL.Type::"G/L Account");
                    SL.SetFilter("Line No.", '%1..', Line."Line No.");

                    LastIndex := 0;

                    if SL.FindSet() then
                        repeat
                            // ---------------------------------------------------------
                            // CASE 1: ITEM LINE → Add as a new row
                            // ---------------------------------------------------------
                            if (SL.Type = SL.Type::Item) And (SL."No." = Line."No.") then begin
                                QuantityList.Add(Format(SL.Quantity));
                                PriceList.Add(SL."Unit Price");
                                LineAmtList.Add(SL."Line Amount");
                                LineType.Add(1);

                                // New entry → Carriage defaults to 0
                                CarriageAmtList.Add(0);

                                PreviousItemNo := SL."No.";
                                LastIndex := LineAmtList.Count();
                            end

                            // ---------------------------------------------------------
                            // CASE 2: G/L LINE immediately below Item
                            // ---------------------------------------------------------
                            else
                                if (SL.Type = SL.Type::"G/L Account") and (PreviousItemNo = Line."No.") then begin
                                    if LastIndex > 0 then begin
                                        // Save GL amount into carriage list
                                        CarriageAmtList.Set(LastIndex, CarriageAmtList.Get(LastIndex) + SL.Amount);

                                        // Add GL amount to total line amount
                                        NewAmt := LineAmtList.Get(LastIndex) + SL."Line Amount";
                                        LineAmtList.Set(LastIndex, NewAmt);
                                    end;
                                end
                                else
                                    break;

                        until SL.Next() = 0;

                    PriceBreakdown_Integer.SetRange(Number, 1, QuantityList.Count());
                end;

            }
        }
    }

    rendering
    {
        layout("Quote Presentation")
        {
            Type = Word;
            LayoutFile = '.\SRC\Report Layout\Quote Presentation 2.docx';
        }
        layout("Sales Quotation (item per page)")
        {
            Type = RDLC;
            LayoutFile = '.\SRC\Report Layout\Sales Quotation Ext.rdl';
        }
    }

    trigger OnPreReport()
    begin
        MyCompanyInfo.Get();
    end;

    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SellToContactEmail: Text;
        GoodsTotal: Decimal;
        CurrencySymbol: Text[10];
        WebDescription: Text;
        QuantityList: List of [Text];
        PriceList: List of [Decimal];
        LineAmtList: List of [Decimal];
        CarriageAmtList: List of [Decimal];
        LineType: List of [Integer];
        LastItem: Text;
        MyCompanyInfo: Record "Company Information";


    local procedure FindNextLineNo(): Integer
    var
        SL: Record "Sales Line";
        NextLineNo: Decimal;
        ISExist: Boolean;
    begin
        ISExist := false;
        Clear(SL);
        sl.SetRange("Document Type", SalesLine."Document Type"::Quote);
        sl.SetRange("Document No.", Header."No.");
        sl.SetFilter(Type, '%1', sl.Type::Item);
        sl.SetFilter("Line No.", '%1..', Line."Line No." + 1);
        if sl.FindSet() then
            repeat
                if SL."No." <> Line."No." then begin
                    NextLineNo := sl."Line No.";
                    ISExist := true;
                    break;
                end;
            until sl.Next() = 0;
        if ISExist = false then begin
            Clear(SL);
            sl.SetRange("Document Type", SalesLine."Document Type"::Quote);
            sl.SetRange("Document No.", Header."No.");
            if sl.FindLast() then
                NextLineNo := sl."Line No.";
        end;
        exit(NextLineNo);
    end;
}