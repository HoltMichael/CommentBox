/*
	Author: Michael Holt
	Date: 13th September 2017

	Test class for the EmailMessageUtils class
*/

@isTest
private class EmailMessageUtils_Test {
	
	/*
		Setup users for 
	*/
	@testSetup static void setupTest() {
		Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User usr1 = new User(LastName = 'Holt',
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

        User usr2 = new User(LastName = 'Holt',
                     FirstName='Michael',
                     Alias = 'Micky',
                     Email = 'sfmicky@commentboxtest.com',
                     Username = 'notOwner@commentboxtest.com',
                     ProfileId = profileId.id,
                     TimeZoneSidKey = 'GMT',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = 'UTF-8',
                     LocaleSidKey = 'en_US'
                     );
        insert new List<User>{usr1,usr2};
	}


	@isTest static void publishCaseEmailEventTest() {
		User u = [SELECT Id from User WHERE Username='sfmicky@commentboxtest.com']; 

		Case c1 = new Case(Subject = 'Case 1', ownerId=u.id);
		Case c2 = new Case(Subject = 'Case 2', ownerId=u.id);
		insert new List<Case>{c1,c2};

		EmailMessage e1 = new EmailMessage(Subject='Email 1', parentId=c1.id);
		EmailMessage e2 = new EmailMessage(Subject='Email 2', parentId=c2.id);
		//This will provide coverage to the trigger, but testing by calling the method directly
		List <EmailMessage> ems = new List<EmailMessage>(new List<EmailMessage>{e1,e2});
		insert ems;

		//How to test this method? Doesn't insert or return anything and there is no trigger on the event
		EmailMessageUtils.publishCaseEmailEvent(ems);

	}
	
	@isTest static void insertCaseCommentTest() {
		User u = [SELECT Id from User WHERE Username='sfmicky@commentboxtest.com']; 


		Case c1 = new Case(Subject = 'Case 1', ownerId=u.id);
		Case c2 = new Case(Subject = 'Case 2', ownerId=u.id);
		insert new List<Case>{c1,c2};

		EmailMessage e1 = new EmailMessage(Subject='Email 1', TextBody='Case', parentId=c1.id);
		EmailMessage e2 = new EmailMessage(Subject='Email 2', TextBody='Case', parentId=c2.id);

		test.startTest();
			EmailMessageUtils.insertCaseComment(new List<EmailMessage>{e1,e2});
		test.stopTest();

		List<CaseComment> CaseComments = [SELECT id, CommentBody FROM CaseComment];

		system.assertEquals(2, CaseComments.size());
		system.assert(CaseComments[0].CommentBody.contains('Case'));
	}
	
}
















