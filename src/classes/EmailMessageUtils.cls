/*
    Author Michael Holt
    Date: 13/09/2017

    Utility class for Email Messages within the CommentBox namespace
*/
Public Class EmailMessageUtils{
    /*
        publishCaseEmailEvent
        Takes the incoming list of emails related to case (trigger on email message)
        Loops through and retrieves the relevant cases. If the current user has access 
        and is the owner of those cases, publish the event to the event bus
    */
    public static void publishCaseEmailEvent(List<EmailMessage> caseEmails){
        List< CommentBox__Email_Event__e > emailEvents = new List< CommentBox__Email_Event__e >();
        List<Id> caseIds = new List<Id>();
        boolean access = CommentBoxController.hasCaseAccess(true);

        for(EmailMessage em :caseEmails){
            caseIds.add(em.parentId);
        }

        if(access = true){
            List<Case> cases = [SELECT ownerId, id, caseNumber, subject FROM Case WHERE Id IN:CaseIds];
        
            for(Case c : cases){
                if(c.ownerId == UserInfo.getUserId()){
                    emailEvents.add(new CommentBox__Email_Event__e(Email_Subject__c = c.subject, Case_Id__c=c.id, Case_Number__c = c.caseNumber));
                }
            }
            EventBus.publish(emailEvents);
        }
    }


    /*
        insertCaseComment
        Inserts a case comment (if the user has access) with the details of the email which has come
        in and is related to the case
    */
    public static void insertCaseComment(List<EmailMessage> caseEmails){
        List<CaseComment> ccom = new List<CaseComment>();
        boolean access;

        for(EmailMessage em : caseEmails){
            String combod = 'To: ' + em.toAddress;
            if(em.CcAddress != null){
                combod += '\nCC: ' + em.CcAddress;
            }
            if(em.TextBody!=null){
                combod += '\n\n' + em.TextBody;
            }else if(em.HtmlBody != null){
                combod += '\n\n' + em.HtmlBody;
            }

            //Check we have access to create a casecomment
            if(!Schema.sObjectType.CaseComment.fields.CommentBody.isUpdateable() && !Schema.sObjectType.CaseComment.fields.parentId.isUpdateable()){
                throw new System.NoAccessException();
                access = false;
            }
            ccom.add(new CaseComment(parentId=em.parentId, CommentBody=combod));
        }

        insert ccom;
    }

}












