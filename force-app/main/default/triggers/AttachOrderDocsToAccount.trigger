trigger AttachOrderDocsToAccount on ContentDocumentLink (after insert) {
    List <ContentDocumentLink> newFiles = new List <ContentDocumentLink>();
    Map <String,String> accIdbyOrdId = new Map <String,String>();
    for(ContentDocumentLink cont:Trigger.new){
        if(cont.LinkedEntityId!=null&&String.valueof(cont.LinkedEntityId).left(3)=='801'){
            accIdbyOrdId.put(cont.LinkedEntityId,'');
        }
    }
    for(Order ord:[select id,Accountid from Order where id in:accIdbyOrdId.keySet()])
        accIdbyOrdId.put(ord.Id,ord.Accountid);
    for(ContentDocumentLink cont:Trigger.new){
        if(accIdbyOrdId.containsKey(cont.LinkedEntityId)&&accIdbyOrdId.get(cont.LinkedEntityId)!=''){
            newFiles.add(
                new ContentDocumentLink(
                    LinkedEntityId=accIdbyOrdId.get(cont.LinkedEntityId),
                    ContentDocumentId=cont.ContentDocumentId,
                    ShareType=cont.ShareType,
                    Visibility=cont.Visibility
                )
            );
        }
    }
    if(newFiles.size()>0)	insert newFiles;
}