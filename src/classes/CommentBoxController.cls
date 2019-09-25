/*
    Author Michael Holt
    Date: 12/08/2017

    Controller for the lightning component CommentBox.cmp
*/

Public With Sharing Class CommentBoxController{

    public static String messageBody;
    public static String invalidEmails = '';
    public static List<Id> attachmentIds = new List<Id>();
    public static final String EMAIL_SUCCESS = 'Comment Sent!';
    public static final String INTERNAL_SUCCESS = 'Private Comment Saved!';
    public static final String INVALID_EMAILS = 'One or more emails failed to send. Please review in Case Comments';

    
    /*
        getCase
        Queries the required fields for output onto the component
        Ensures that the contact email is in the "To" field on the component
    */ 
    @AuraEnabled
    public static Case getCase(id caseId){
        List<String> caseAccessFields = getCaseFields(true);
        Map<String,Schema.SObjectField> caseMap = Schema.SObjectType.case.fields.getMap();
        
        boolean access = checkAccess(false);
        
        if(access){
            Case c = [SELECT id, CommentBox__Email_Case_Followers__c, CommentBox__Public__c, CommentBox__threadId__c, CaseNumber, Subject, Contact.name, ContactEmail, Contact.id, CommentBox__Comment_Body__c, CommentBox__to_addresses__c, CommentBox__cc_addresses__c, CommentBox__bcc_addresses__c
                        FROM Case
                        WHERE Id=:caseId];
            c.CommentBox__Public__c = true;
            c.CommentBox__To_addresses__c = c.CommentBox__To_addresses__c == null ? '' : c.CommentBox__To_addresses__c;

            if(c.ContactEmail != null){
                if(!(c.CommentBox__To_addresses__c).contains(c.ContactEmail)){
                    if(c.CommentBox__To_addresses__c.length() > 0){
                        c.CommentBox__To_addresses__c += ';';
                    }
                    c.CommentBox__To_addresses__c += c.ContactEmail;
                }
            }
            return c;
        }else{
            return null;
        }
    }

    /*
        getCaseFields
        Retrieves all of the fields relevant for this component as Strings in a list
        ReadOnly parameter indicates whether an update is going to be performed (so don't check whether
        you can edit fields which are read only)
    */
    public static List<String> getCaseFields(boolean readOnly){
        List<String> fields = new List<String>{
                                                'Subject',
                                                'CommentBox__Email_Case_Followers__c',
                                                'CommentBox__Comment_Body__c',
                                                'CommentBox__to_addresses__c',
                                                'CommentBox__cc_addresses__c',
                                                'CommentBox__bcc_addresses__c',
                                                'CommentBox__Public__c'};
        if(readOnly){
            fields.addAll(new List<String>{'Id', 'CommentBox__threadId__c', 'CaseNumber'});
        }
        return fields;
    }

    /*
        hasCaseAccess
        Performs the necessary FLS checks in order to ascertain whether the current
        user has access to the fields.
        readOnly parameter indicates whether this is for view or edit purposes
    */
    public static boolean hasCaseAccess(boolean readOnly){
        List<String> caseAccessFields = getCaseFields(readOnly);

        Map<String,Schema.SObjectField> caseMap = Schema.SObjectType.case.fields.getMap();
        boolean access = true;
        for(String field : caseAccessFields){
            // Check if the user has access to read the fields
            if (!caseMap.get(field).getDescribe().isAccessible()) {
                throw new System.NoAccessException();
                access = false;
            }
        }
        return access;
    }

    /*
        Checks the access of the current user to the fields in the
        getCaseFields method. Can be read only = true for view, or false for edit
    */
    @AuraEnabled
    public static boolean checkAccess(boolean readOnly){
        List<String> caseAccessFields = getCaseFields(readOnly);
        Map<String,Schema.SObjectField> caseMap = Schema.SObjectType.case.fields.getMap();
        boolean access = true;
        for(String field : caseAccessFields){
            // Check if the user has access to edit the fields
            if (!caseMap.get(field).getDescribe().isUpdateable()) {
                throw new System.NoAccessException();
                access = false;
            }
        }
        //Check the contact Field
        if(!Schema.sObjectType.Contact.fields.name.isAccessible()){
            throw new System.NoAccessException();
            access = false;
        }
        return access;
    }

    
    /*
        saveCase
        Updates the current case with the information provided on the page (addresses, status & follower information)
        Removes the text from the comment body and inserts into the case comment, along with recipient information
    */
    @AuraEnabled
    public static String saveCase(case thisCase, List<String> attachments){
        if(checkAccess(false) == false){
            return null;
        }

        if(attachments != null){        
            setAttachmentIds(attachments);
        }        
        messageBody = thisCase.CommentBox__Comment_Body__c;
        thisCase.CommentBox__Comment_Body__c = '';
        update thisCase;

        if(thisCase.CommentBox__Email_Case_Followers__c){
            String followers = getCaseFollowers(thisCase.id);
            //If there are already CC addresses, add a semi-colon before adding the case followers                                                    
            if(thisCase.CommentBox__CC_Addresses__c != '' & thisCase.CommentBox__cc_addresses__c !=null){
                thisCase.CommentBox__CC_Addresses__c += ';';
            }
            if(thisCase.CommentBox__CC_Addresses__c == null){
                thisCase.CommentBox__CC_Addresses__c = '';
            }
            thisCase.CommentBox__CC_Addresses__c += followers;
        }

        String successMessage;
        if(thisCase.CommentBox__Public__c){
            successMessage = sendEmail(thisCase);
        }else{
            successMessage = INTERNAL_SUCCESS;

        }

        //Insert the case comment only if an email was sent & add any relevant addresses
        //Or if it's a private comment
        CaseComment Comment = new CaseComment(ParentId =thisCase.id);
        Comment.CommentBody = '';
        if(successMessage.contains(EMAIL_SUCCESS)){
            comment.CommentBody = 'To: ' + thisCase.CommentBox__to_addresses__c;
            if(thisCase.CommentBox__CC_Addresses__c != null){
                comment.CommentBody += '\nCC: ' + thisCase.CommentBox__CC_Addresses__c;
            }

            //Add any invalid emails to the comment and the toast
            if(invalidEmails != ''){
                comment.CommentBody += '\nEmail failures: ' + invalidEmails;
                successMessage += '\n\n' + INVALID_EMAILS;
            }

            comment.CommentBody += '\n\n';
        }

        if(successMessage.contains(EMAIL_SUCCESS) || !thisCase.CommentBox__Public__c){
            comment.CommentBody += messageBody;
            comment.IsPublished = thisCase.CommentBox__Public__c;
            insert comment;
        }

        return successMessage;
    }

    /*
        setAttachmentIds
        Attachments are set on the JS controller as ContentDocument
        Emails only accept ContentVersion, so go through the attached ContentDocuments
        and retrieve the ID of the latest version to attach
    */
    private static void setAttachmentIds(List<String>attachments){
        for (ContentDocument doc : [SELECT id, LatestPublishedVersionId  
                                    FROM ContentDocument 
                                    WHERE id 
                                    in:attachments]){
            attachmentIds.add(doc.LatestPublishedVersionId);
        }
    }


    /*
        getCaseFollowers
        Retrieves the case followers and adds their emails to a string of emails to be returned
    */
    @AuraEnabled
    public static String getCaseFollowers(id caseId){
        //Do the access checks..
        if(!Schema.sObjectType.User.fields.email.isAccessible()){
            throw new System.NoAccessException();
            return null;
        }

        String followers = '';
        List<user> users = [SELECT Id, email FROM user WHERE ID in
                                                        (SELECT SubscriberId
                                                        FROM EntitySubscription 
                                                        WHERE ParentId=:caseId)];
        for(user u : users){
            followers += u.email + ';';
        }

        return followers;
    }

    /*
        sendEmail
        Establishes a new SingleEmailMessage and populates details from component in order
        to send the message. Calls a number of methods for validating email strings
    */
    public static string sendEmail(case thisCase){

        String errors = '';
        boolean orgWideError = false;
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<OrgWideEmailAddress> emailList = getCommentBoxEmail();

        //Set the "From Address" to be CommentBox address retrieved above
        //Do not set an org wide email address in test context. Cannot perform DML on org wide email
        //This is the reason we require the dodgy orgwideerror variable too
        //Overwrite the error variable because we don't care about anything if the app hasn't been configured
        if(!test.isRunningTest()){
            if(emailList.size() == 1){
                email.setOrgWideEmailAddressId(emailList[0].id);
            }else if(emailList.size() == 0){
                Errors = Label.No_CommentBox_Address;
                orgWideError = true;
            }else{
                Errors = Label.Multiple_CommentBox_Addresses;
                orgWideError = true;
            }
        }

        if(orgWideError == false){
            List<String> bccEmails = splitEmails(thisCase.CommentBox__BCC_addresses__c);
            List<String> ccEmails = splitEmails(thisCase.CommentBox__CC_addresses__c);
            List<String> toEmails = splitEmails(thisCase.CommentBox__To_addresses__c);

            email.setBccAddresses(bccEmails);
            email.setCcAddresses(ccEmails);
            email.setToAddresses(toEmails);
            email.setWhatId(thisCase.id);
            email.setHTMLBody(messageBody);
            //email.setPlainTextBody(messageBody);
            email.setSubject(thisCase.subject + '[' + thisCase.CommentBox__threadId__c + ']');

            system.debug(attachmentIds);
            if(attachmentIds.size() > 0){
                system.debug(attachmentIds);
                email.setEntityAttachments(new List<Id>(attachmentIds));
            }

            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {email};
            
            try{
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                errors += EMAIL_SUCCESS;
            }catch (System.EmailException e){
                errors+= e;
            }
        }

        return errors;
    }

    /*
        getCommentBoxEmail
        Queries the org wide email address used for email2case
        Must be configured by subscribers prior to app use
    */
    public static List<OrgWideEmailAddress> getCommentBoxEmail(){
        //Do the access checks..
        if(!Schema.sObjectType.OrgWideEmailAddress.fields.id.isAccessible()){
            throw new System.NoAccessException();
            return null;
        }

        List<OrgWideEmailAddress> emailList= [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName='CommentBox'];
        return emailList;
    }

    /*
        splitEmails
        Breaks a large string of emails up by the semi-colon delimeter
        Adds to an overall list of invalid emails which will ultimately be placed on the case comment
    */
    public static List<String> splitEmails(String emails){
        if(emails != null && emails !=''){
            List<String> splitMail = emails.split(';');
            List<String> validMail = new List<String>();
            
            for(String s : splitMail){
                if(isValidEmail(s)){
                    validMail.add(s);
                }else{
                    invalidEmails += s + ';';
                }
            }
            return validMail;
        }else{
            return new List<String>();
        }
    }

    /*
        isValidEmail
        Uses a regex expression retrieved here below to determine validity of email. Returns true if valid 
        https://developer.salesforce.com/forums/?id=906F000000092GXIAY
    */
    public static boolean isValidEmail(String address){
        String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
        Pattern emailPattern = Pattern.compile(emailRegex);
        Matcher comparison = emailPattern.matcher(address);
        return comparison.matches();
    }
}