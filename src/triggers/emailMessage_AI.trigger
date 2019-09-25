trigger emailMessage_AI on EmailMessage (After Insert) {
    List<EmailMessage> caseEmails = new List<EmailMessage>();    
    String casePrefix = Schema.getGlobalDescribe().get('Case').getDescribe().getKeyPrefix();

    for(EmailMessage em : Trigger.new){
        String parentId = em.ParentId;
        if(parentId.left(3) == casePrefix){
            caseEmails.add(em);
        }
    }
    
    if(caseEmails.size() > 0){
        EmailMessageUtils.publishCaseEmailEvent(caseEmails);
        EmailMessageUtils.insertCaseComment(caseEmails);
    }
}