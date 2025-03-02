@isTest
public with sharing class Milestone1_Calendar_ItemTest {
    @IsTest
static void testCalendarItem()
    {
        Milestone1_Calendar_Item calItem = new Milestone1_Calendar_Item('ABCDEFG','UNIT TEST',Date.today(),Milestone1_Calendar_Item.PROJECT_TYPE);
        system.assertEquals('UNIT TEST',calItem.name);
        system.assertEquals('ABCDEFG', calItem.aid);
        system.assertEquals(Date.today(),calItem.theDate);
    }
}