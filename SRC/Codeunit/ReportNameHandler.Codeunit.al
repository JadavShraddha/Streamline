codeunit 50100 ReportNameHandler
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, OnGetFilename, '', false, false)]
    local procedure OnGetFilename(ReportID: Integer; Caption: Text[250]; ObjectPayload: JsonObject; FileExtension: Text[30]; ReportRecordRef: RecordRef; var Filename: Text; var Success: Boolean)
    var
        OrderNo: Text;
        CustomerName: Text;
        FieldRef: FieldRef;
        test: Text;
    begin
        if ReportRecordRef.Number = 0 then
            exit;

        if (ReportID = Report::NeuSalesQuote) Or (ReportID = Report::"Standard Sales - Order Conf.") or (ReportID = Report::"Standard Purchase - Order") then begin
            // Get Order No.
            if ReportRecordRef.FieldExist(3) then begin
                FieldRef := ReportRecordRef.Field(3);
                OrderNo := Format(FieldRef.Value);
            end;

            // Get Customer Name
            if ReportRecordRef.FieldExist(5) then begin
                FieldRef := ReportRecordRef.Field(5);
                CustomerName := Format(FieldRef.Value);
            end;

            // Replace spaces, avoid invalid characters
            CustomerName := DelChr(CustomerName, '=', '\/:*?"<>|');
            Filename := OrderNo + ' ' + CustomerName + FileExtension;
            Success := true;
        end;
    end;
}
