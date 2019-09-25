/*
	Author: Michael Holt
	Date: 13th September 2017
*/

Public Class NotificationController{

	/*
		Call the commentboxcontroller method which checks whether the user has relevant
		access to the fields required for commentbox to run
	*/
	@AuraEnabled
	public static boolean checkAccess(){
		try{
			return CommentBoxController.checkAccess(false);
		}catch(System.NoAccessException e){
			return false;
		}
	}
    
    /*
		Get the session Id of the current user in order to subscribe to the
		platform event
    */
    @AuraEnabled
    public static String getSessionId() {
        return UserInfo.getSessionId();
    }
}