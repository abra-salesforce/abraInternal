global with sharing class AsyncNavIntegrationSchedulable implements Schedulable{
    global void execute(SchedulableContext context){
        ID jobID = System.enqueueJob(new AsyncNavIntegrationQueueable(null,null));
    }
}