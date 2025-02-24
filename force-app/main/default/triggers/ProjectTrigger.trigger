trigger ProjectTrigger on Project__c (after insert, after update) {
    Set <String> templateIds = new Set <String>();
    for(Project__c proj:Trigger.new){
        if(proj.Scope_Template__c!=null)    templateIds.add(proj.Scope_Template__c);
    }
    Map<Id,List <Project_Milestone__c>> projectMilestones = new Map<Id,List <Project_Milestone__c>>();
    List <Project_Milestone__c> projectMilestones4ins = new List <Project_Milestone__c>();
    Map <String,Scope_Template__c> templates = new Map <String,Scope_Template__c>([select id,(select id,Days_from_Start__c,Recurring__c,Recurring_Interval__c,Payment_Milestone__c,Name,Description__c,Full_Description__c,Type__c,Payment_percent__c,Hide_from_Gantt__c from Project_Milestones__r) from Scope_Template__c where id in:templateIds]);
    for(Project__c pr:Trigger.new){
        //copy milestones
        if(pr.Scope_Template__c!=null&&pr.Start_Date__c!=null&&pr.Due_Date__c!=null&&templates.containsKey(pr.Scope_Template__c)&&templates.get(pr.Scope_Template__c).Project_Milestones__r.size()>0&&(Trigger.isInsert||Trigger.oldMap.get(pr.Id).Start_Date__c==null||Trigger.oldMap.get(pr.Id).Due_Date__c==null||Trigger.oldMap.get(pr.Id).Scope_Template__c==null)){
            for(Project_Milestone__c proj:templates.get(pr.Scope_Template__c).Project_Milestones__r){
                projectMilestones.put(pr.id, new List<Project_Milestone__c>());
                if(proj.Recurring__c!=null&&proj.Recurring_Interval__c!=null){
                    Date dat;
                    while(dat==null||dat<=pr.Due_Date__c){
                        if(dat==null)  {
                            dat = pr.Start_Date__c;
                            if(proj.Days_from_Start__c!=null)   dat = dat.addDays(Integer.valueof(proj.Days_from_Start__c));
                        }
                        projectMilestones.get(pr.id).add(new Project_Milestone__c(
                            Name = proj.Name,
                            Description__c = proj.Description__c,
                            Payment_Milestone__c = proj.Payment_Milestone__c,
                            Due_Date__c = dat,
                            Project__c = pr.Id,
                            Payment_percent__c = proj.Payment_percent__c,
                            Type__c = proj.Type__c,
                            Full_Description__c = proj.Full_Description__c,
                            Hide_from_Gantt__c = proj.Hide_from_Gantt__c
                        ));
                        if(proj.Recurring__c=='Month')  dat = dat.addMonths(Integer.valueof(proj.Recurring_Interval__c));
                        else if(proj.Recurring__c=='Week')  dat = dat.addDays(Integer.valueof(proj.Recurring_Interval__c)*7);
                        else  dat = dat.addDays(Integer.valueof(proj.Recurring_Interval__c));
                    }
                } else if(proj.Days_from_Start__c!=null){
                    projectMilestones.get(pr.id).add(new Project_Milestone__c(
                        Name = proj.Name,
                        Description__c = proj.Description__c,
                        Payment_Milestone__c = proj.Payment_Milestone__c,
                        Due_Date__c = pr.Start_Date__c.addDays(Integer.valueof(proj.Days_from_Start__c)),
                        Project__c = pr.Id,
                        Payment_percent__c = proj.Payment_percent__c,
                        Type__c = proj.Type__c,
                        Full_Description__c = proj.Full_Description__c,
                        Hide_from_Gantt__c = proj.Hide_from_Gantt__c
                    ));
                } else {
                    projectMilestones.get(pr.id).add(new Project_Milestone__c(
                        Name = proj.Name,
                        Description__c = proj.Description__c,
                        Payment_Milestone__c = proj.Payment_Milestone__c,
                        Due_Date__c = pr.Due_Date__c,
                        Project__c = pr.Id,
                        Payment_percent__c = proj.Payment_percent__c,
                        Type__c = proj.Type__c,
                        Full_Description__c = proj.Full_Description__c,
                        Hide_from_Gantt__c = proj.Hide_from_Gantt__c
                    ));
                }
                projectMilestones4ins.addAll(projectMilestones.get(pr.id));
            }
        }
    }
    if(projectMilestones4ins.size()>0)  insert projectMilestones4ins;
    //add files
    List <ContentDocumentLink> links4ins = new List <ContentDocumentLink>();
    Set<Id> projIds = projectMilestones.keySet();
    if(projIds.size()>0){
        for(ContentDocumentLink link:[select id,ContentDocumentId,LinkedEntityId from ContentDocumentLink where LinkedEntityId IN: projIds]){
            for(Project_Milestone__c proj:projectMilestones.get(link.LinkedEntityId)){
                links4ins.add(new ContentDocumentLink(LinkedEntityId = proj.id,ContentDocumentId = link.ContentDocumentId));
            }
        }
        if(links4ins.size()>0)     insert links4ins;
    }
}