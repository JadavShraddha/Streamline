reportextension 50101 "Proforma Invoice Ext" extends "Standard Sales - Pro Forma Inv"
{
    dataset
    {
        addfirst(Line)
        {
            dataitem(LineItem; Item)
            {
                DataItemLink = "No." = field("No.");
                column("CommodityCode"; "Tariff No.") { }
                column("CountryOfOrigin"; "Country/Region of Origin Code") { }
            }
        }

        add(Line)
        {
            column(No_; "No.") { }
        }

        add(Header)
        {
            column(Company_Name; CompanyInformation."Ship-to Name") { }
            column(Company_Ship_to_Address; CompanyInformation."Ship-to Address") { }
            column(Company_Ship_to_Address_2; CompanyInformation."Ship-to Address 2") { }
            column(Company_Ship_to_City; CompanyInformation."Ship-to City") { }
            column(Company_Ship_to_Post_Code; CompanyInformation."Ship-to Post Code") { }
            column(Company_Ship_to_Country_Code; CompanyInformation."Country/Region Code") { }
            column(TotalQty; TotalQty) { }
            column(Quote_No_; "Quote No.") { }
            column(Company_Bank_Account_Code;CompanyInformation."Bank Name") { }
            column(Company_Bank_Branch_No;CompanyInformation."Bank Branch No.") { }
            column(Company_Bank_Account_No;CompanyInformation."Bank Account No.") { }
            column(Company_IBAN; CompanyInformation.IBAN) { }
            column(Company_SWIFT_Code; CompanyInformation."SWIFT Code") { }
        }

        addfirst(Header)
        {
            dataitem(ZZ_Ship_to_Address_STR_Integer; Integer)
            {
                column(Number; Number) { }
                column(ShipToAddr; ShipToAddress.Get(Number)) { }

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
                    ZZ_Ship_to_Address_STR.SetRange("Sales Order No.", Header."No.");

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
                            Header."Ship-to Name",
                            Header."Ship-to Address",
                            Header."Ship-to Address 2",
                            Header."Ship-to City",
                            Header."Ship-to Country/Region Code",
                            Header."Ship-to Post Code");

                        if ShipAdd <> '' then
                            ShipToAddress.Add(ShipAdd);
                    end;

                    TotalShipToAddress := ShipToAddress.Count();
                    ZZ_Ship_to_Address_STR_Integer.SetRange(Number, 1, TotalShipToAddress);
                end;
            }

        }

        modify(line)
        {
            trigger OnAfterAfterGetRecord()
            begin
                if Line.Type = Line.Type::Item then
                    TotalQty := TotalQty + Line.Quantity;
            end;
        }
    }

    rendering
    {
        layout("Proforma InvoiceTemplate - Piotr")
        {
            Type = RDLC;
            LayoutFile = '.\SRC\Report Layout\Proforma InvoiceTemplate - Piotr.rdl';
        }
    }

    var
        TotalQty: Decimal;
        ShipToAddress: List of [Text];

    local procedure BuildShipToAddress(Name: Text; Address1: Text; Address2: Text; City: Text; Country: Text; PostCode: Text): Text
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