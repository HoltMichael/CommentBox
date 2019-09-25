/*
    Author Michael Holt
    Date: 19/08/2017

    Test class for the CommentBoxController_Test Class.
*/
@isTest
Public Class commentBoxTemplatesController_Test{

    @testSetup static void setupTest() {

        //Profile and user
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User usr = new User(LastName = 'Holt',
                     FirstName='Michael',
                     Alias = 'Micky',
                     Email = 'sfmicky@commentboxtest.com',
                     Username = 'sfmicky@commentboxtest.com',
                     ProfileId = profileId.id,
                     TimeZoneSidKey = 'GMT',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = 'UTF-8',
                     LocaleSidKey = 'en_US'
                     );
        insert usr;

        EmailTemplate email1 = new EmailTemplate (developerName = 'test1', folderId = usr.id, TemplateType= 'Text', Name = 'test1', body='test1');
        EmailTemplate email2 = new EmailTemplate (developerName = 'test2', folderId = usr.id, TemplateType= 'Text', Name = 'test2');
        EmailTemplate email3 = new EmailTemplate (developerName = 'test3', folderId = usr.id, TemplateType= 'custom', Name = 'test3');
        EmailTemplate email4 = new EmailTemplate (developerName = 'test4', folderId = usr.id, TemplateType= 'Text', Name = 'test4');
        EmailTemplate email5 = new EmailTemplate (developerName = 'test5', folderId = usr.id, TemplateType= 'Text', Name = 'test5');
        insert new List<EmailTemplate>{email1,email2,email3,email4,email5};
    }

    /*
        getFoldersTest
        Not possible to insert folders, but we can still test that the
        personal folder is there
    */
    static testMethod void getFoldersTest(){
        boolean assertion = false;
        test.startTest();
            for(Folder f :commentBoxTemplatesController.getFolders()){
                if(f.Name == 'My Personal Email Templates'){
                    assertion = true;
                }
            }
        test.stopTest();
        system.assertEquals(true, assertion);

    }   


    /*
        getTemplatesTest
        We inserted 1 HTML (Custom) Email, so we only expect 4 to come back out
    */
    static testMethod void getTemplatesTest(){
        user u = [SELECT id FROM user WHERE Username='sfmicky@commentboxtest.com'];
        String idString = (String)u.id;
        Test.startTest();
            system.assertEquals(4, commentBoxTemplatesController.getTemplates(idString).size());
        Test.stopTest();
    }

    static testMethod void getEmailBodyTest(){
        EmailTemplate et = [SELECT id FROM EmailTemplate WHERE developerName = 'test1'];
        test.startTest();
            system.assertEquals('test1', commentBoxTemplatesController.getEmailBody(et.id));
        test.stopTest();
    }
}