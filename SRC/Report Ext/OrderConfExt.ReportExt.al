reportextension 50100 "Order Conf. Ext" extends "Standard Sales - Order Conf."
{
    dataset
    {
        add(Header)
        {
            column(Salesperson_Code; SalespersonPurchaser.Name){}
            column(SalespersonPurchaser_Email; SalespersonPurchaser."E-Mail"){}
            column(SalespersonPurchaser_Phone;SalespersonPurchaser."Phone No."){}
            column(Sell_to_Contact;"Sell-to Contact"){}
            column(Currency_Symbol;CurrencySymbol){}
            column(CompanyShipToAddress;CompanyInfo."Ship-to Address"){}
            column(CompanyShipToAddress2;CompanyInfo."Ship-to Address 2"){}
            column(CompanyShipToCity;CompanyInfo."Ship-to City"){}
            column(CompanyShipToPostCode;CompanyInfo."Ship-to Post Code"){}
            column(Registration_Number; CompanyInfo."Registration No.") { }
            column(Company_Reg_Name; CompanyInfo."Registered Name") { }
            column(Company_Reg_Address; CompanyInfo."Registered Address") { }
            column(Company_Reg_City; CompanyInfo."Registered City") { }
            column(Company_Reg_Postcode; CompanyInfo."Registered Post Code") { }

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

                SalesEmail := '';
                if Contact.Get("Sell-to Contact No.") then
                    SalesEmail := Contact."E-Mail";
            end;
        }

        add(Line)
        {
            column(GoodsTotal; GoodsTotal) { }
            column(CC; CC) { }
            column(Item_Picture; item.Picture){}
            column(CarriageAmount;CarriageAmount){}
            column(Unit_Price;"Unit Price"){}
        }

        addbefore(AssemblyLine)
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
            dataitem("Sales Line";"Sales Line")
            {
                column(No_;"No."){}
                column(Line_No_;"Line No."){}
                column(Type;Type){}
                column(Comment_Description;Description){}
                column(Quantity;Quantity){}
                column(Line_Amount;"Line Amount"){}
                

                trigger OnAfterGetRecord()
                begin
                    GoodsTotal += "Line Amount";     
                    if "Sales Line".Type = "Sales Line".Type::"G/L Account" then
                        begin
                            CC += "Sales Line"."Line Amount";
                            // CurrReport.Skip();
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    "Sales Line".SetRange("Document Type", SalesLine."Document Type"::Order);
                    "Sales Line".SetRange("Document No.", Header."No.");
                    "Sales Line".SetFilter(Type, '%1|%2|%3|%4|%5', Type::"Allocation Account", Type::"Charge (Item)", Type::"G/L Account", Type::"Fixed Asset", Type::Resource);
                    "Sales Line".SetFilter("Line No.", '%1..%2', Line."Line No.", FindNextLineNo());
                end;
            }
        }

        modify(Line)
        {
            trigger OnAfterPreDataItem()
            begin
                Line.SetFilter(Type, '%1', Type::Item);
            end;

            trigger OnAfterAfterGetRecord()
            var 
                SL: Record "Sales Line";
            begin
                Clear(CarriageAmount);
                Clear(CarriageAmount);
                Clear(CC);
                Clear(Quantity);


                GoodsTotal := 0;
                GoodsTotal := Line."Line Amount";
                Clear(Item);
                If Line.Type = Line.Type::Item then
                    Item.Get(Line."No.");

                SL.SetFilter("Document Type", '%1', SalesLine."Document Type"::Order);
                SL.SetFilter("Document No.", '%1', Header."No.");
                SL.SetFilter(Type, '%1|%2', SL.Type::"G/L Account", SL.Type::Item);
                SL.SetFilter("Line No.", '%1..', Line."Line No.", "Sales Line"."Line No." + 1);
                if "Sales Line".FindSet() then
                repeat
                    if SL.Type = SL.Type::"G/L Account" then
                        CarriageAmount += SL."Line Amount"
                    else if (SL.Type = SL.Type::Item) then
                        break;
                until "Sales Line".Next() = 0;

                GoodsTotal += CarriageAmount;
            end;
        }
    }
    
    rendering
    {
        layout("Order Acknowledgement")
        {
            Type = RDLC;
            LayoutFile = '.\SRC\Report Layout\Order Acknowledgement After Changes.rdl';
        }
    }

    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        GoodsTotal: Decimal;
        CurrencySymbol: Text[10];
        SalesEmail: Text;
        CC: Decimal;
        CarriageAmount: Decimal;
        

        local procedure FindNextLineNo(): Integer
        var
            SL: Record "Sales Line";
            ISExist: Boolean;
            NextLineNo: Decimal;
        begin
            Clear(SL);
            sl.SetRange("Document Type", SalesLine."Document Type"::Order);
            sl.SetRange("Document No.", Header."No.");
            sl.SetFilter(Type, '%1', sl.Type::Item);
            sl.SetFilter("Line No.", '%1..', Line."Line No." + 1);
            if sl.FindFirst() then
                NextLineNo := sl."Line No."
            else begin
                Clear(SL);
                sl.SetRange("Document Type", SalesLine."Document Type"::Order);
                sl.SetRange("Document No.", Header."No.");
                if sl.FindLast() then
                    NextLineNo := sl."Line No.";
            end;
            exit(NextLineNo);
        end;
}