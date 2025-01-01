global class Working_HoursZedRollScheduler implements Schedulable {
global void execute(SchedulableContext SC) {
itmyway_zr.Queue.scheduleJob('Working_HoursZedRollScheduler','Working_Hours__c',null);
}
}