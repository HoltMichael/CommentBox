/*
    Author Michael Holt
    Date: 13/08/2017

    Test class for the CommentBoxController Class.
*/

@isTest
public class CommentBoxController_Test {

    @testSetup static void setupTest() {
        //Create contact and cases
        Contact c = new Contact(firstName = 'Michael', lastName = 'Holt', email = 'test@example.com');
        Insert c;
        
        Case case1 = new Case(Status = 'new', Subject = '1');
        Case case2 = new Case(Status = 'new', Subject = '2');
        Case case3 = new Case(Status = 'new', ContactId = c.id, Subject = '3');
        insert new List<Case>{case1,case2,case3};

        //Profile and user
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
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
        //Make the user follow case 3
        EntitySubscription ES = new EntitySubscription(ParentId = case3.id, SubscriberId = usr.id);
        insert ES;
    }

    /*
        getCaseFieldsTest
        Ensure all the fields are returned when requested
        Ensure the read only fields are not returned when boolean is false
    */
    static testMethod void getCaseFieldsTest(){
        List<String> editFieldsString = CommentBoxController.getCaseFields(true);
        Set<String> editFields = new Set<String>(editFieldsString);
        List<String> readOnlyFieldsString = CommentBoxController.getCaseFields(false);
        Set<String> readOnlyFields = new Set<String>(readOnlyFieldsString);

        system.assertEquals(true, editFields.contains('Subject'));
        system.assertEquals(true, editFields.contains('CommentBox__Email_Case_Followers__c'));
        system.assertEquals(true, editFields.contains('CommentBox__Comment_Body__c'));
        system.assertEquals(true, editFields.contains('CommentBox__to_addresses__c'));
        system.assertEquals(true, editFields.contains('CommentBox__cc_addresses__c'));
        system.assertEquals(true, editFields.contains('CommentBox__bcc_addresses__c'));
        system.assertEquals(true, editFields.contains('Id'));
        system.assertEquals(true, editFields.contains('CommentBox__threadId__c'));
        system.assertEquals(true, editFields.contains('CaseNumber'));

        system.assertEquals(false, readOnlyFields.contains('Id'));
        system.assertEquals(false, readOnlyFields.contains('CommentBox__threadId__c'));
        system.assertEquals(false, readOnlyFields.contains('CaseNumber'));      
    }

    /*
        getCaseTest
        Ensure the correct Case is returned (by checking the subject)
        Ensure that the To_Addresses__C has been populated with the contact email address
    */
    static testMethod void getCaseTest(){
        Case testCase = [SELECT ID from CASE WHERE ContactId != null];

        Test.startTest();
            System.assertEquals('3', CommentBoxController.getCase(testCase.id).Subject);
            System.assertEquals('test@example.com', CommentBoxController.getCase(testCase.id).CommentBox__To_Addresses__c);
        Test.stopTest();
    }

    /*
        getCaseFollowers
        Test that the address of any followers is added to the CC field
    */
    static testMethod void getCaseFollowersTest(){
        Case testCase = [SELECT ID from CASE WHERE ContactId != null];

        Test.startTest();
            testCase.CommentBox__CC_Addresses__c = null;
            CommentBoxController.getCase(testCase.id);
            String email = CommentBoxController.getCaseFollowers(testCase.id);
            system.assertEquals('sfmicky@commentboxtest.com;', email);
        Test.stopTest();
    }

    /*
        splitEmailsTest
        Pass a string containing 2 genuine emails and several mistakes. Ensure 2 emails are returned
    */
    static testMethod void splitEmailsTest(){
        String emails = 'micky1@salesforce.com;;;micky2@salesforce.com;micky3,@salesforce.com;micky@.com';
        
        test.startTest();
            system.assertEquals(2, CommentBoxController.splitEmails(emails).size());
        test.stopTest();
    }

    /*
        isValidEmailTest
        Provide a selection of valid and invalid emails and ensure they come back correctly
    */
    static testMethod void isValidEmailTest(){
        test.startTest();
            system.assert(CommentBoxController.isValidEmail('micky1@salesforce.com'));
            system.assert(CommentBoxController.isValidEmail('micky-2@salesforce.com'));
            system.assert(CommentBoxController.isValidEmail('micky3@sales-force.com'));
            system.assert(!CommentBoxController.isValidEmail('m!icky3@salesforce.com'));
            system.assert(!CommentBoxController.isValidEmail('micky3 @salesforce.com'));
            system.assert(!CommentBoxController.isValidEmail('micky3@salesforce..com'));
            system.assert(!CommentBoxController.isValidEmail('mic@ky3@salesforce.com'));
        test.stopTest();
    }

    /*
        hasCaseAccessTest
        Checks whether the current running user has access to case fields
        Running in sys admin mode, this should return true
    */
    static testMethod void hasCaseAccessTest(){
        test.startTest();
            system.assertEquals(CommentBoxController.hasCaseAccess(true), true);
        test.stopTest();
    }

    /*
        saveCaseTest
        Ensure that the case is updated and the case comment is inserted    
    */
    static testMethod void saveCaseTest(){
        Case testCase = [SELECT ID from CASE WHERE ContactId != null];
        testCase.CommentBox__Comment_Body__c = 'Hello, \nThis is a test case comment.';
        testCase.CommentBox__BCC_addresses__c = 'micky1@salesforce.com';
        testCase.CommentBox__CC_addresses__c = null;
        testCase.CommentBox__To_addresses__c = 'micky2@salesforce.com';
        testCase.CommentBox__Email_Case_Followers__c = true;
        testCase.CommentBox__Public__c = true;

        test.startTest();
            CommentBoxController.saveCase(testCase, new List<String>());
        test.stopTest();

        //Query the case back up and ensure the updates have happened, except the body, which we do not save
        Case testCase2 = [SELECT ID, CommentBox__Comment_Body__c, CommentBox__CC_addresses__c, CommentBox__BCC_addresses__c, CommentBox__To_addresses__c from CASE WHERE ContactId != null];
        system.assertEquals(null, testCase2.Comment_Body__c);
        system.assertEquals('micky2@salesforce.com', testCase2.CommentBox__To_addresses__c);
        system.assertEquals('micky1@salesforce.com', testCase2.CommentBox__BCC_addresses__c);

        //Ensure the body has been saved to a case comment, including the CC address of the user following the case
        CaseComment comment = [SELECT id, CommentBody FROM CaseComment WHERE ParentId =: testCase2.id];
        system.debug(comment.CommentBody);
        system.assert(comment.CommentBody.contains('This is a test case comment.'));
        system.assert(comment.CommentBody.contains('CC: sfmicky@commentboxtest.com'));
    }

    /*
        sendEmailTest
        Ensure that an email is sent when the body and to address is provided
    */
    static testMethod void sendEmailTest(){
        Case testCase = [SELECT ID from CASE WHERE ContactId != null];
        testCase.CommentBox__Comment_Body__c = 'Hello, \nThis is a test case comment.';
        testCase.CommentBox__To_addresses__c = 'micky2@salesforce.com';
        update testCase;

        test.startTest();
            system.assertEquals(0, Limits.getEmailInvocations());
            CommentBoxController.saveCase(testCase, null);
            String response = CommentBoxController.sendEmail(testCase);
            system.assertEquals(commentBoxController.EMAIL_SUCCESS, response);
            system.assertEquals(1, Limits.getEmailInvocations());
        test.stopTest();
    }
}