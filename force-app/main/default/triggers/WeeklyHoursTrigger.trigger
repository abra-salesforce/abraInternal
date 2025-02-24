trigger WeeklyHoursTrigger on Weekly_Hours__c (before insert, after insert) {

    if(Trigger.isBefore){
        if(Trigger.New.size()==1)   Trigger.new[0].addError('You cannot add weekly hours');
    } else {
        Map <String,Map <Date,String>> extras = new Map<String,Map <Date,String>>();
        Set <String> contsids = new Set<String>();
        Set <Date> dats = new Set<Date>();


        for(Weekly_Hours__c wk:Trigger.new){

            if(wk.Start_Date__c.addDays(6).Month()!=wk.Start_Date__c.Month()){

                Date dat = Date.newInstance(wk.Start_Date__c.Year(), wk.Start_Date__c.Month(), 1);
                dat = dat.addMonths(1);

                if(!extras.containsKey(wk.Contact__c))  extras.put(wk.Contact__c, new Map <Date,String>());

                extras.get(wk.Contact__c).put(dat,wk.id);
                contsids.add(wk.Contact__c);
                dats.add(dat);

            }
        }

        List <Monthly_Hours__c> monts = [select id,Contact__c,Date__c,Weekly_Hours_extra__c from Monthly_Hours__c where Contact__c in:contsids and Date__c in:dats];

        for(Monthly_Hours__c mt:monts){
            mt.Weekly_Hours_extra__c = extras.get(mt.Contact__c).get(mt.Date__c);
        }

        update monts;
    }
}