reportextension 50104 "Neu Delivery Note Ext" extends NeuDeliveryNote
{
    dataset
    {
         add(Header)
        {
            column(Company_Ship_to_Name; CompanyInfo2."Ship-to Name") { }
            column(Company_Ship_to_Address; CompanyInfo2."Ship-to Address") { }
            column(Company_Ship_to_Address_2; CompanyInfo2."Ship-to Address 2") { }
            column(Company_Ship_to_City; CompanyInfo2."Ship-to City") { }
            column(Company_Ship_to_Post_Code; CompanyInfo2."Ship-to Post Code") { }
            column(Company_Ship_to_Country_Code; CompanyInfo2."Country/Region Code") { }
        }
    }

    trigger OnPreReport()
    begin
        CompanyInfo2.Get();
    end;

    var
        CompanyInfo2: Record "Company Information";
}