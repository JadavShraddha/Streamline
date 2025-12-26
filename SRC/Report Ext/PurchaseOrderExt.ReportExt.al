reportextension 50103 "Purchase Order Ext" extends "Standard Purchase - Order"
{
    dataset
    {
        add("Purchase Header")
        {
            column(Purchaseperson_Code; SalespersonPurchaser.Code) { }
            column(PurchasepersonPurchaser_Email; SalespersonPurchaser."E-Mail") { }
            column(Currency_Symbol; CurrencySymbol) { }
            column(Buy_from_Contact; "Buy-from Contact") { }
            column(Company_Name; CompanyInfo."Ship-to Name") { }
            column(Company_address; CompanyInfo."Ship-to Address") { }
            column(company_add2; CompanyInfo."Ship-to Address 2") { }
            column(Company_City; CompanyInfo."Ship-to City") { }
            column(Company_Post_Code; CompanyInfo."Ship-to Post Code") { }
            column(comapany_Fax; companyInfo."Fax No.") { }
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

                Clear(ShipToAddress);
            end;
        }
        add("Purchase Line")
        {
            column(GoodsTotal; GoodsTotal) { }
            column(Item_Picture; Item.Picture) { }
            column(Item_Description_2; item."Description 2") { }
            column(Line_Unit_Cost;"Unit Cost"){}
        }
        addfirst("Purchase Line")
        {
            dataitem(PurchaseLine; "Purchase Line")
            {
                column(No_; PurchaseLine."No.") { }
                column(Line_No_; PurchaseLine."Line No.") { }
                column(Type; PurchaseLine.Type) { }
                column(PurchaseLine_Description; PurchaseLine.Description) { }
                column(Quantity; PurchaseLine.Quantity) { }
                column(Line_Amount; PurchaseLine."Line Amount") { }
                column(Unit_Cost; PurchaseLine."Unit Cost") { }
                column(Unit_of_Measure; PurchaseLine."Unit of Measure") { }

                trigger OnAfterGetRecord()
                begin
                    GoodsTotal += "Line Amount";
                end;

                trigger OnPreDataItem()
                begin
                    PurchaseLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                    PurchaseLine.SetRange("Document No.", "Purchase Header"."No.");
                    PurchaseLine.SetFilter(Type, '%1|%2|%3|%4|%5', Type::"Allocation Account", Type::"Charge (Item)", Type::"G/L Account", Type::"Fixed Asset", Type::Resource);
                    PurchaseLine.SetFilter("Line No.", '%1..%2', "Purchase Line"."Line No.", FindNextLineNo());
                end;
            }
            dataitem(PurchaseLineComment; "Purchase Line")
            {
                column(Comment_No_; PurchaseLineComment."No.") { }
                column(Comment_Line_No_; PurchaseLineComment."Line No.") { }
                column(Comment_Description; PurchaseLineComment.Description) { }

                trigger OnPreDataItem()
                begin
                    PurchaseLineComment.SetRange("Document Type", PurchaseLineComment."Document Type"::Order);
                    PurchaseLineComment.SetRange("Document No.", "Purchase Header"."No.");
                    PurchaseLineComment.SetFilter(Type, '%1', Type::" ");
                    PurchaseLineComment.SetFilter("Line No.", '%1..%2', "Purchase Line"."Line No.", FindNextLineNo());
                end;
            }
            dataitem(ZZ_Ship_to_Address_STR_Integer; Integer)
            {
                column(Number; Number) { }
                column(ShipToAddr; ShipToAddress.Get(Number)) { }

                // trigger OnAfterGetRecord()
                // begin
                    
                // end;
                trigger OnPreDataItem()
                var
                    ZZ_Ship_to_Address_STR: Record "ZZ Ship-to Address STR";
                    ShipAdd: Text;
                    TotalShipToAddress: Integer;
                begin
                    Clear(ShipToAddress);
                    Clear(TotalShipToAddress);

                    ZZ_Ship_to_Address_STR.Reset();
                    ZZ_Ship_to_Address_STR.SetRange("Document Type", ZZ_Ship_to_Address_STR."Document Type"::Order);
                    ZZ_Ship_to_Address_STR.SetRange("Sales Order No.", "Purchase Line"."ZZ Sales Order No.");
                    ZZ_Ship_to_Address_STR.SetFilter("Sales Line No.", Format("Purchase Line"."ZZ Sales Order Line No."));

                    if ZZ_Ship_to_Address_STR.FindSet() then
                        repeat
                            ShipAdd := BuildShipToAddress(
                                ZZ_Ship_to_Address_STR."Ship-to Name",
                                ZZ_Ship_to_Address_STR.Address,
                                ZZ_Ship_to_Address_STR."Address 2",
                                ZZ_Ship_to_Address_STR.City,
                                ZZ_Ship_to_Address_STR.Country,
                                ZZ_Ship_to_Address_STR."Post Code");

                            if ShipAdd <> '' then
                                ShipToAddress.Add(ShipAdd);
                        until ZZ_Ship_to_Address_STR.Next() = 0;

                    if ShipToAddress.Count() = 0 then begin
                        ShipAdd := BuildShipToAddress(
                            "Purchase Header"."Ship-to Name",
                            "Purchase Header"."Ship-to Address",
                            "Purchase Header"."Ship-to Address 2",
                            "Purchase Header"."Ship-to City",
                            "Purchase Header"."Ship-to Country/Region Code",
                            "Purchase Header"."Ship-to Post Code");

                        if ShipAdd <> '' then
                            ShipToAddress.Add(ShipAdd);
                    end;

                    TotalShipToAddress := ShipToAddress.Count();
                    ZZ_Ship_to_Address_STR_Integer.SetRange(Number, 1, TotalShipToAddress);
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
        Item: Record Item;
        GoodsTotal: Decimal;
        CurrencySymbol: Text[10];
        PurchaseEmail: Text;
        ShipToAddress: List of [Text];

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

    local procedure BuildShipToAddress(Name: Text;Address1: Text;Address2: Text;City: Text;Country: Text;PostCode: Text): Text
    var
        Result: Text;
    begin
        if Name <> '' then
            Result += Name + ', ';
        if Address1 <> '' then
            Result += Address1 + ', ';
        if Address2 <> '' then
            Result += Address2 + ', ';
        if City <> '' then
            Result += City + ', ';
        if Country <> '' then
            Result += Country + ', ';
        if PostCode <> '' then
            Result += PostCode;

        exit(DelChr(Result, '>', ', '));
    end;

}