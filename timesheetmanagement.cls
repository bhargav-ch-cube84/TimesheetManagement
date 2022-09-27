public class timesheetmanagement 
{    
    Public List<Timesheet_Entry__c> oldEntries;
    Public List<Timesheet_Entry__c> otherentries;
    Public Map<String, Timesheet_Entry__c> existingMap = new Map<String, Timesheet_Entry__c>();
    Public Date SelectedWeek;
    Public Timesheet_Entry__c timesheetEntry {get; set;}
    Public ID caseId;
    Public String SelectedProgram;
    
    public timesheetmanagement(ApexPages.StandardController controller){
        if(timesheetEntry == NULL) {
            timesheetEntry = new Timesheet_Entry__c();
        }
    }
    
    public void onloadfunction()
    {
        oldEntries = new List<Timesheet_Entry__c>();
        if(otherentries!=null){
            oldEntries.addAll(otherentries);
        }
        if (timesheetEntry.Week_Start_Date__c != null)
        {
            SelectedWeek = timesheetEntry.Week_Start_Date__c.toStartofWeek()+1;   
            system.debug('The Selected Week is'+SelectedWeek);
        } 
        else
        {
            Date currentdate = date.today();
            SelectedWeek = currentdate.toStartofWeek()+1; 
            system.debug('The Selected Week is'+SelectedWeek);
        }    
        timesheetEntry.Week_Start_Date__c = SelectedWeek;
        if(caseId == NULL){
            caseId = ApexPages.currentPage().getParameters().get('id');
        }
        //if(otherentries!=NULL && !otherentries.isEmpty()) {
            List<Timesheet_Entry__c> lst = [select Id,Case__c,Tasks_Other__c,Week_Start_Date__c,Mon__c,Tue__c,Wed__c,Thu__c,Fri__c,Sat__c,Sun__c from Timesheet_Entry__c where Week_Start_Date__c=:SelectedWeek and CreatedById=:Userinfo.getUserId() AND Case__c=:caseId];
            otherentries = new List<Timesheet_Entry__c>();
            if(!lst.isEmpty()) {
                Timesheet_Entry__c finalEntry = new Timesheet_Entry__c(Id=lst[0].Id);
                for(Timesheet_Entry__c entry : lst) {
                    existingMap.put(entry.Tasks_Other__c, entry);
                    finalEntry.Mon__c = sumDoubles(finalEntry.Mon__c, entry.Mon__c);
                    finalEntry.Tue__c = sumDoubles(finalEntry.Tue__c, entry.Tue__c);
                    finalEntry.Wed__c = sumDoubles(finalEntry.Wed__c, entry.Wed__c);
                    finalEntry.Thu__c = sumDoubles(finalEntry.Thu__c, entry.Thu__c);
                    finalEntry.Fri__c = sumDoubles(finalEntry.Fri__c, entry.Fri__c);
                    finalEntry.Sat__c = sumDoubles(finalEntry.Sat__c, entry.Sat__c);
                    finalEntry.Sun__c = sumDoubles(finalEntry.Sun__c, entry.Sun__c);
                }
                otherentries.add(finalEntry);
            }
        //}
        addrowothers();
    }       
    public List<Timesheet_Entry__c> getotherentrylist()
    {
        if (otherentries!=NULL && otherentries.size()>0) 
            return otherentries;
        else
            return null;    
    }  
    
    public void addrowothers()
    {
        system.debug('The Selected Week is'+SelectedWeek);
        Timesheet_Entry__c newentry = new Timesheet_Entry__c(Week_Start_Date__c=SelectedWeek, Case__c=caseId);
        if(otherentries == NULL || otherentries.isEmpty())
        {
            otherentries = new List<Timesheet_Entry__c>{newentry};
        } 
        else {
            otherentries.add(otherentries.size()-1, newentry);
        }
        oldEntries.clear();
        oldEntries.addAll(otherentries);
    }    
    public Pagereference savetimesheet()
    {
        try
        {
            if(otherentries.size()>1){
                if(otherentries[otherentries.size()-1].Id != NULL){
                    otherentries.remove(otherentries.size()-1);
                }
                Map<String, Timesheet_Entry__c> finalMap = new Map<String, Timesheet_Entry__c>();
                for(Integer i=0; i<otherentries.size(); i++) {
                    Timesheet_Entry__c loopEntry = otherentries[i];
                    if(String.isBlank(loopEntry.Tasks_Other__c) || finalMap.containsKey(loopEntry.Tasks_Other__c)){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Task is Required and should not be duplicated'));
						return null;
                    }
                    if(existingMap.containsKey(loopEntry.Tasks_Other__c)) {
                        Timesheet_Entry__c entry = existingMap.get(loopEntry.Tasks_Other__c);
                        Timesheet_Entry__c finalEntry = new Timesheet_Entry__c(Id=entry.Id);
                        finalEntry.Mon__c = sumDoubles(loopEntry.Mon__c, entry.Mon__c);
                        finalEntry.Tue__c = sumDoubles(loopEntry.Tue__c, entry.Tue__c);
                        finalEntry.Wed__c = sumDoubles(loopEntry.Wed__c, entry.Wed__c);
                        finalEntry.Thu__c = sumDoubles(loopEntry.Thu__c, entry.Thu__c);
                        finalEntry.Fri__c = sumDoubles(loopEntry.Fri__c, entry.Fri__c);
                        finalEntry.Sat__c = sumDoubles(loopEntry.Sat__c, entry.Sat__c);
                        finalEntry.Sun__c = sumDoubles(loopEntry.Sun__c, entry.Sun__c);
                        finalMap.put(loopEntry.Tasks_Other__c, finalEntry);
                    } else {
                        finalMap.put(loopEntry.Tasks_Other__c,loopEntry);
                    }
                }
                upsert finalMap.values();
            } else {
                if(String.isBlank(otherentries[0].Tasks_Other__c)){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Task is Required and should not be duplicated'));
                    return null;
                }
                upsert otherentries;
            }

            Pagereference p = Page.timesheetmanagement; 
            return p;   
        }
        catch(Exception e){ return null;}
        
    }
    
    public Decimal sumDoubles(Decimal num1, Decimal num2) {
        if(num1 != NULL && num2 != NULL) {
            return num1 + num2;
        } else if(num1 != NULL){
            return num1;
        } else {
            return num2;
        }
    }

}