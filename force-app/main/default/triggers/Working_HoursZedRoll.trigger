trigger Working_HoursZedRoll on Working_Hours__c (after insert,after update,after delete,after undelete) {
ITmyWay_ZR.Queue.checkChanges((List <sobject>)Trigger.new, (Map <Id,sobject>)Trigger.oldmap, Trigger.isInsert||Trigger.isUndelete,Trigger.isDelete);
}