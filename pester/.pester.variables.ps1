# save as '.test.variables.ps1' to hide from git
# hold static value to be used by Pester

# connection info for CW server used for Pester 
$pstrSvrUrl        = "https://api-na.myconnectwise.net/v2016_3/apis/3.0";
$pstrCompany       = "connectwise";
$pstrSvrPublicKey  = "PQlRvXUAqLiXi062";
$pstrSvrPrivateKey = "yfYD9sg13eDtB236";

# example ticket numbers to use for testing
$pstrTicketID  = 7617515
$pstrTicketIDs =  @(7617515, 7787839, 7738721);

# example board numbers to use for testing 
$pstrBoardID = 297
$pstrBoardIDs = @(1,2,3,250,297)
