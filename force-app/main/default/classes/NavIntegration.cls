public with sharing class NavIntegration {
    public InnerClass InnerClass;
    public static Map <String,Map <String,String>> projectByTypeByDepartment = new Map <String,Map <String,String>>{
        'IT'=>new Map <String,String>{
            'VACATION'=>'8002',
            'SICKNESS'=>'8002',
            'RESERVES'=>'8002',
            'CHILD ILLNESS'=>'8002',
            'UNPAID'=>'8002',
            'PREGNANCY'=>'8002'
        },
        'Salesforce'=>new Map <String,String>{
            'VACATION'=>'8001',
            'SICKNESS'=>'8001',
            'RESERVES'=>'8001',
            'CHILD ILLNESS'=>'8001',
            'UNPAID'=>'8001',
            'PREGNANCY'=>'8001'
        }
    };
    public static Map <String,Map <String,String>> taskByTypeByDepartment = new Map <String,Map <String,String>>{
        'IT'=>new Map <String,String>{
            'VACATION'=>'1000',
            'SICKNESS'=>'2000',
            'RESERVES'=>'3000',
            'CHILD ILLNESS'=>'4000',
            'UNPAID'=>'5000',
            'PREGNANCY'=>'6000'
        },
        'Salesforce'=>new Map <String,String>{
            'VACATION'=>'1000',
            'SICKNESS'=>'2000',
            'RESERVES'=>'3000',
            'CHILD ILLNESS'=>'4000',
            'UNPAID'=>'5000',
            'PREGNANCY'=>'6000'
        }
    };
	public class InnerClass {
		public String id;
		public String type;
		public String projectId;
		public String taskId;
		public String startDate;
		public String startTime;
		public String endDate;
		public String endTime;
		public Boolean billable;
		public String comments;
		public String userName;
		public String ReportLocation;
		public Decimal PsaBreak;
        public String param1;
        public String ErrorMessage;
        public InnerClass(Working_Hours__c wh, Boolean Billable){
            Decimal hours;
            if(Billable==true){
                hours = wh.Billable_Hours__c;
                this.id = wh.Nav_ID__c;
            } else {
                hours = wh.Non_Billable_Hours__c;
                this.id = wh.Nav_ID_Non_Billable__c;
            }
            this.type               = 'WORK';
            this.projectId          = wh.Project__r.Parent_Project__r.Project_Number__c; // '1001' == status code 200 in test
            this.taskId             = wh.Project__r.Project_Number__c; // '1000' == status code 200 in test   
            if(wh.RecordType.Name=='IT'&&wh.Start__c!=null){
                this.startDate          = string.valueOf(Date.newInstance(wh.Start__c.year(),wh.Start__c.month(),wh.Start__c.day()));
                this.startTime          = NavIntegration.convertTimeToStr(Time.newInstance(9, 0, 0, 0));// allways 9 for calculate amout of hours
                this.endDate            = string.valueOf(Date.newInstance(wh.Start__c.year(),wh.Start__c.month(),wh.Start__c.day()));
                this.endTime            = NavIntegration.wHEndTime(hours);                          // this.starttime + billableHours
            } else {
                this.startDate          = string.valueOf(wh.Date__c);
                this.startTime          = NavIntegration.convertTimeToStr(Time.newInstance(9, 0, 0, 0));                          // allways 9 for calculate amout of hours
                this.endDate            = string.valueOf(wh.Date__c);
                this.endTime            = NavIntegration.wHEndTime(hours); // this.starttime + billableHours
            }
            this.billable           = Billable;
            this.comments           = wh.Description_Of_Work__c!=null?wh.Description_Of_Work__c.left(250):null;
            this.userName           = wh.Performed_By_2__r.Email; // 'Edan.Badani@abra-it.com' == status code 200 in test                     
            this.ReportLocation     = wh.Working_Day__c!=null?(wh.Working_Day__r.Location__c!='Home'?'Office':'Home'):'Home'; 
            this.PsaBreak           = 0;
            this.param1             = wh.Id+(billable?';true':';false');                                        // use the salesforce id for mapping
        }
        public InnerClass(Working_Days__c wd){                              
            this.id                 = wd.Nav_ID__c;
            this.type               = wd.Nav_Type__c;
            this.projectId          = projectByTypeByDepartment.get(wd.Performed_By_contact__r.Department).get(this.type); // '1001' == status code 200 in test
            this.taskId             = taskByTypeByDepartment.get(wd.Performed_By_contact__r.Department).get(this.type); // '1000' == status code 200 in test   
            this.startDate          = string.valueOf(Date.newInstance(wd.Start__c.year(),wd.Start__c.month(),wd.Start__c.day()));
            this.startTime          = NavIntegration.convertTimeToStr(wd.Start__c.time());// allways 9 for calculate amout of hours
            this.endDate            = string.valueOf(Date.newInstance(wd.End__c.year(),wd.End__c.month(),wd.End__c.day()));
            this.endTime            = NavIntegration.convertTimeToStr(wd.End__c.time());                          // this.starttime + billableHours
            this.billable           = false;
            this.comments           = null;
            this.userName           = wd.Performed_By_contact__r.Email; // 'Edan.Badani@abra-it.com' == status code 200 in test                     
            this.ReportLocation     = 'Home'; 
            this.PsaBreak           = 0;
            this.param1             = wd.Id;                                        // use the salesforce id for mapping
        }   
	}
	
    public static String convertTimeToStr(Time t){
        String str = string.valueOf(t);
        return (str.left(str.length()-5));
    }
    public static String wHEndTime(Decimal hours){ 
        Decimal hoursAndMins = (9 + hours);
        System.debug('hoursAndMins: ' + hoursAndMins);
        Decimal hrs = Math.floor(hoursAndMins);
        Decimal mints = hoursAndMins-hrs;
        Integer mintsInt = (mints*60).intValue();
        // Need to be exactly like abra format hh:mm:ss
        String str = (hrs<10?'0':'')+hrs+':'+(mintsInt<10?'0':'')+mintsInt+':00';  
        System.debug('wHEndTime: ' + str);
        return str;
    }        
    public static String createJsonForAllWH(List<Working_Hours__c> workingHours){
        List<InnerClass> innerClasses = new List<InnerClass>();
        for (Working_Hours__c wh : workingHours) {
            if(wh.Billable_Hours__c>0)  innerClasses.add(new innerClass(wh, true));
            if(wh.Non_Billable_Hours__c>0)  innerClasses.add(new innerClass(wh, false));
        }
        return JSON.serialize(innerClasses);
    }
    public static String createJsonForAllWD(List<Working_Days__c> workingDays){
        List<InnerClass> innerClasses = new List<InnerClass>();
        for (Working_Days__c wd : workingDays) 
            innerClasses.add(new innerClass(wd));
        return JSON.serialize(innerClasses);
    }
    public static String ifNull(String field){ return (field == null ? 'null' : field);}
    public static List<InnerClass> parse(String json){ 
        return (List<InnerClass>) System.JSON.deserialize(json, List<InnerClass>.class);
    }
}