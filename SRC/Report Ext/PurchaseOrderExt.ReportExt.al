reportextension 50103 "Purchase Order Ext" extends "Standard Purchase - Order"
{
    dataset
    {
       add("Purchase Header")
       {
            column(Purchaseperson_Code; SalespersonPurchaser.Code) { }
            column(PurchasepersonPurchaser_Email; SalespersonPurchaser."E-Mail") { }
            column(Currency_Symbol; CurrencySymbol) { }
            column(Buy_from_Contact;"Buy-from Contact"){}
            column(Company_Name;CompanyInfo."Ship-to Name"){}
            column(Company_address;CompanyInfo."Ship-to Address"){}
            column(company_add2; CompanyInfo."Ship-to Address 2"){}
            column(Company_City;CompanyInfo."Ship-to City"){}
            column(Company_Post_Code;CompanyInfo."Ship-to Post Code"){}
            column(comapany_Fax; companyinfo."Fax No."){}
       }
       modify("Purchase Header")
        {
            trigger OnAfterAfterGetRecord()
            var
                GLS: Record "General Ledger Setup";
                Currency: Record Currency;
                Contact: Record Contact;
            begin
                if "Purchase Header"."Currency Code" = '' then begin
                    if GLS.Get() then
                        CurrencySymbol := GLS."Local Currency Symbol";
                end
                else
                    if Currency.Get("Purchase Header"."Currency Code") then
                        CurrencySymbol := Currency.Symbol;

                PurchaseEmail := '';
                if Contact.Get("Buy-from Contact No.") then
                    PurchaseEmail := Contact."E-Mail";
            end;
        }
        add("Purchase Line")
        {
            column(GoodsTotal; GoodsTotal) { }
            column(Item_Picture; Item.Picture) { }
        }
        addfirst("Purchase Line")
        {
            dataitem("NEU Item Builder Header"; "NEU Item Builder Header")
            {
                DataItemLinkReference = "Purchase Line";
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("Document No."), "Line No." = field("Line No.");

                column(IS_Document_No_; "Document No.") { }
                dataitem(Item_Specification; "NEU Item Specifications")
                {
                    // DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No."), "Document Line No." = field("Line No."), "Item Category Code" = field("Item Category");

                    column(IS_Item_Category_Code; "Item Category Code") { }
                    column(Item_Specification_Code; "Item Specification Code") { }
                    column(Item_Specification_Text; "Item Specification Text") { }
                    column(Comments; Comments) { }
                    column(Purchase_Comments; "Purchase Comments") { }
                    column(IS_Line_No_; "Line No.") { }
                    column(IS_Document_Line_No_; "Document Line No.") { }

                    trigger OnPreDataItem()
                    begin
                        Item_Specification.SetRange("Purchase Comments", True);
                        Item_Specification.SetRange("Document Type", "NEU Item Builder Header"."Document Type");
                        Item_Specification.SetRange("Document No.", "NEU Item Builder Header"."Document No.");
                        Item_Specification.SetRange("Document Line No.", "NEU Item Builder Header"."Line No.");
                        Item_Specification.SetRange("Item Category Code", "NEU Item Builder Header"."Item Category");
                    end;
                }
            }
            dataitem(PurchaseLine; "Purchase Line")
            {
                column(No_; "No.") { }
                column(Line_No_; "Line No.") { }
                column(Type; Type) { }
                column(Comment_Description; Description) { }
                column(Quantity; Quantity) { }
                column(Line_Amount; "Line Amount") { }

                trigger OnAfterGetRecord()
                begin
                    GoodsTotal += "Line Amount";
                end;

                trigger OnPreDataItem()
                begin
                    PurchaseLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                    PurchaseLine.SetRange("Document No.", "Purchase Header"."No.");
                    PurchaseLine.SetFilter(Type, '%1|%2|%3|%4|%5|%6', Type::"Allocation Account", Type::"Charge (Item)", Type::"G/L Account", Type::"Fixed Asset", Type::Resource, Type::" ");
                    PurchaseLine.SetFilter("Line No.", '%1..%2', "Purchase Line"."Line No.", FindNextLineNo());
                end;
            }
        }

        modify("Purchase Line")
        {
            trigger OnAfterPreDataItem()
            begin
                "Purchase Line".SetFilter(Type, '%1', Type::Item);
            end;

            trigger OnAfterAfterGetRecord()
            begin
                GoodsTotal := 0;
                GoodsTotal := "Purchase Line"."Line Amount";

                Clear(Item);
                If "Purchase Line".Type = "Purchase Line".Type::Item then
                    Item.Get("Purchase Line"."No.")
            end;
        }
    }
    
    requestpage
    {
        // Add changes to the requestpage here
    }
    
    rendering
    {
        layout("Purchase - Order Custom")
        {
            Type = RDLC;
            LayoutFile = '.\SRC\Report Layout\Purchase Order Print.rdl';
        }
    }
    var
        PurchLine: Record "Purchase Line";
        GoodsTotal: Decimal;
        CurrencySymbol: Text[10];
        Item: Record Item;
        PurchaseEmail: Text;

    local procedure FindNextLineNo(): Integer
    var
        PL: Record "Purchase Line";
        NextLineNo: Decimal;
    begin
        Clear(PL);
        PL.SetRange("Document Type", PurchLine."Document Type"::Order);
        PL.SetRange("Document No.", "Purchase Header"."No.");
        PL.SetFilter(Type, '%1', PL.Type::Item);
        PL.SetFilter("Line No.", '%1..', "Purchase Line"."Line No." + 1);
        if PL.FindFirst() then
            NextLineNo := PL."Line No."
        else begin
            Clear(PL);
            PL.SetRange("Document Type", PurchLine."Document Type"::Order);
            PL.SetRange("Document No.", "Purchase Header"."No.");
            if PL.FindLast() then
                NextLineNo := PL."Line No.";
        end;

        exit(NextLineNo);
    end;
}