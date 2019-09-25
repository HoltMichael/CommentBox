/*
	Author: Michael Holt
	Date: 13th September 2017

	Test class for the Notification Controller class
*/


@isTest
private class NotificationController_Test {
	
	/*
		Setup the test data
	*/
	@testSetup static void setupNotificationControllerTests(){
		//User with access to case object
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

        //User without access to case object
		profileId = [SELECT Id FROM Profile WHERE Name = 'Chatter External User' LIMIT 1];
        usr = new User(LastName = 'Holt',
                     FirstName='Michael',
                     Alias = 'Micky',
                     Email = 'sfmicky@commentboxtest.com',
                     Username = 'sfmickynoaccess@commentboxtest.com',
                     ProfileId = profileId.id,
                     TimeZoneSidKey = 'GMT',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = 'UTF-8',
                     LocaleSidKey = 'en_US'
                     );
        insert usr;
	}

	/*
		Test the checkAccess method with a user with access
	*/
	@isTest static void checkAccessTestPositive() {
		User usr = [SELECT id from User WHERE Username='sfmicky@commentboxtest.com'];
		system.runAs(usr){
			system.assertEquals(true, NotificationController.checkAccess());
		}
	}

	/*
		Test the checkAccess method with a user without access
	*/
	@isTest static void checkAccessTestNegative() {
		User usr = [SELECT id from User WHERE Username='sfmickynoaccess@commentboxtest.com'];
		system.runAs(usr){
			system.assertEquals(false, NotificationController.checkAccess());
		}
	}
	
	/*
		Test the getSessionId method
	*/
	@isTest static void getSessionIdTest() {
		test.startTest();
			system.assertEquals(UserInfo.getSessionId(), NotificationController.getSessionId());
		test.stopTest();
	}
	
}