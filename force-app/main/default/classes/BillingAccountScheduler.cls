global class BillingAccountScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        BillingAccountBatch batch = new BillingAccountBatch();
        Database.executeBatch(batch, 200);
    }
}
