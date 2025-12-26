reportextension 50105 "Standard Sales - Invoice Ext" extends "Standard Sales - Invoice"
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

        modify(line)
        {
            trigger OnAfterAfterGetRecord()
            begin
                if Line.Type = Line.Type::Item then
                    TotalQty := TotalQty + Line.Quantity;
            end;
        }

        add(Header)
        {
            column(TotalQty; TotalQty) { }
            column(Company_Pic; CompanyInfo.Picture) {  }
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

    }
    rendering
    {
        layout("SaleInvoiceTemplate - piotr")
        {
            Type = RDLC;
            LayoutFile = '.\SRC\Report Layout\SaleInvoiceTemplate - piotr.rdl';
        }
        layout("Sale Invoice Template EU VAT")
        {
            Type = RDLC;
            LayoutFile = '.\SRC\Report Layout\Sale Invoice Template EU VAT.rdl';
        }
        layout("Proforma InvoiceTemplate - Piotr")
        {
            Type = RDLC;
            LayoutFile = '.\SRC\Report Layout\Proforma Invoice - Piotr.rdl';
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