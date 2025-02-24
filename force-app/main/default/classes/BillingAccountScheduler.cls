global class BillingAccountScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        BillingAccountQueueable queueableJob = new BillingAccountQueueable();
        System.enqueueJob(queueableJob);
    }
}