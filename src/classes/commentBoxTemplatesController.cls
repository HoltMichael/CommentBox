public with sharing class commentBoxTemplatesController {

    /*
        getFolders
        Queries out all email folders, as well as the users' personal
        email folder (based on userId)
    */
    @AuraEnabled
    public static List<Folder> getFolders(){
        List<Folder> options = [SELECT id, name
                                FROM Folder
                                Where Type = 'Email'];
        options.add(new Folder(Name='My Personal Email Templates'));
        if(!Schema.sObjectType.Folder.fields.name.isAccessible()){
            throw new System.NoAccessException();
            return null;
        }else{
            return options;
        }
    }

    /*
        getTemplates
        For a given folder ID, retrieve all of the email templates
        If the folder ID is the personal email folder, update the folderId
        to be the ID of the user
        Currently only supporting Text fields
    */
    @AuraEnabled
    public static List<EmailTemplate> getTemplates(String folderId){
        if(folderId == 'My Personal Email Templates'){
            // Each User has a 'My Personal Templates' folder
            // of EmailTemplates, whose Id is the User's Id
            folderId = UserInfo.getUserId();
        }
        if(!Schema.sObjectType.EmailTemplate.fields.name.isAccessible()){
            throw new System.NoAccessException();
            return null;
        }else{
            return [SELECT Id,Name FROM EmailTemplate WHERE FolderId = :folderId AND templateType='text'];
        }
    }

    /*
        handleEmailSelection
        Identifies which type of template this is and returns the relevant field
        @getTemplates, however, does currently only support text
    */
    @AuraEnabled
    public static String getEmailBody(String emailId){
        String body = '';
        EmailTemplate template = [SELECT id, name, body, htmlValue, markup, templateType FROM EmailTemplate WHERE id=:emailId];

        if(template.templateType == 'text')
        {
            body = template.body;
        }
        if(!Schema.sObjectType.EmailTemplate.fields.name.isAccessible()){
            throw new System.NoAccessException();
            return null;
        }else{
            return body;
        }
    }
}