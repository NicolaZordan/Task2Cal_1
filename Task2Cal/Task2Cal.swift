//
//  Tasks.swift
//  t1
//
//  Created by Nicola Zordan on 12/2/16.
//  Copyright © 2016 CrosaraZordan. All rights reserved.
//

import Foundation
import EventKit


class Task2Cal {

    //var testData = ["a test", "b", "c", "d"]
    //var testData: [String] = []
    
    var eventStore = EKEventStore()

    // Settings
    var calendarMarker = " [Task2Cal]"
    var calendar:EKCalendar?=nil
    var tasks:EKCalendar?=nil
    
    func setDefaultCalendarTasks () {
        calendar = eventStore.defaultCalendarForNewEvents
        tasks = eventStore.defaultCalendarForNewReminders()
    }
    func setCalendar(calendarIn:EKCalendar) {
        calendar=calendarIn
    }
    func setTasks (tasksIn:EKCalendar) {
        tasks=tasksIn
    }
    

    // Data
    var remindersLoaded = false
    //var eventStore: EKEventStore!
    //var reminders: [EKReminder]!
    var reminders: [EKReminder] = []
    var reminderSelected: Int = -1
    var reminder: EKReminder!
    
    
    var debug:Bool=true
    var errored:Bool=false
    var message:String=""
    
    func setNoError () -> Bool {
        return setError(false,message: nil)
    }
    func setErrorMessage (_ message:String?) -> Bool {
        return setError(true, message: nil)
    }
    func setError (_ error:Bool, message:String?) -> Bool {
        errored=error
        if message == nil {
            if errored {
                self.message="some error occurred"
            } else {
                self.message=""
            }
        } else {
            self.message=message!
        }
        if debug {
            if errored {
                print("Error: " + self.message)
            }
        }
        return errored
    }
    func hasErrorMessage () -> Bool {
        errored=(self.message.count > 0)
        return errored
    }
    
    func errorMessage () {
        if message.count < 1 {
            
        }
    }
    
    //func getLoadReminders() {
    //    getReminders(completion: {() -> Void in self.tv.reloadData()})
    //    //getReminders(completion: loadRemindersInTable)
    //}
    
    func countTasks () -> Int {
        return reminders.count
    }
    
    func getTask (_ at:Int) -> String {
        if at >= reminders.count || at<0 {
            //reminderSelected = -1
            _=setErrorMessage("invalid reminder index, get")
            return message
        }
        reminderSelected=at
        reminder=reminders[reminderSelected]
        let reminderTitle=reminder.title
        let taskTitle=removeMarker(reminderTitle!)
        _=setNoError()
        return taskTitle
    }
    
    func setTask (_ at:Int, title:String) -> String {
        //if (reminders == nil) {
        //    setErrorMessage("reminders not loaded, set")
        //    return message
        //}
        if at >= reminders.count || at<0 {
            _=setErrorMessage("invalid reminder index, set")
            return message
        }
        reminderSelected=at
        reminder=reminders[reminderSelected]
        let reminderTitle=addMarker(title)
        reminder.title=reminderTitle
        _=setNoError()
        return reminder.title
    }
    
    func addTaskNoSave (_ title:String) -> Int {
        //if (reminders == nil) {
        //    setErrorMessage("reminders not loaded, add")
        //    return -1
        //}
        //let i=reminders.count
        reminder = EKReminder(eventStore: self.eventStore)
        reminder.title = addMarker(title)
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        reminders.append(self.reminder)
        _=setNoError()
        return reminders.count-1
    }

    func removeTaskNoDelete (_ at:Int) -> Int {
        //if reminders == nil {
        //    setErrorMessage("reminders not loaded")
        //    return -1
        //}
        if at >= reminders.count || at<0 {
            _=setErrorMessage("invalid remnder index, remove")
            return -1
        }
        //reminder=reminders[at]
        reminderSelected = -1
        reminder=reminders.remove(at: at)
        _=setNoError()
        return at
    }
    
    
    func saveTaskNoCompletion (_ at:Int) -> Int {
        if at >= reminders.count || at<0 {
            _=setErrorMessage("invalid remnder index, save")
            return -1
        }
        reminderSelected=at
        reminder = reminders[reminderSelected]
        do {
            try eventStore.save(reminder, commit: true)
        }catch{
            _=setErrorMessage("Error saving reminder [\(at)]: \(error)")
            return -1
        }
        return at
    }
    
    func saveTask (_ at:Int, completion: @escaping (() -> Void) = {() -> Void in }) -> Int {
        if at >= reminders.count || at<0 {
            _=setErrorMessage("invalid remnder index, save")
            return -1
        }
        reminderSelected=at
        reminder = reminders[reminderSelected]
        do {
            try eventStore.save(reminder, commit: true)
            completion()
            _=setNoError()
        }catch{
            _=setErrorMessage("Error saving reminder [\(at)]: \(error)")
            return -1
        }
        return at
    }
    

    func addTask (_ title:String, completion: @escaping (() -> Void) = {() -> Void in }) -> Int {
        let i=addTaskNoSave(title)
        if i<0 {
            return i
        }
        let r=saveTask(i, completion: completion)
        return r
    }
    
    func deleteTask (_ at:Int, completion: @escaping (() -> Void) = {() -> Void in }) -> Int {
        if at >= reminders.count || at<0 {
            _=setErrorMessage("invalid remnder index, delete")
            return -1
        }
        reminder = reminders[at]
        do {
            try eventStore.remove(reminder, commit: true)
            _=setNoError()
            completion()
        }catch{
            _=setErrorMessage("Error removing reminder [\(at)]: \(error)")
            //throw error
            return -1
        }
        return at
    }
    
    func removeTask (_ at:Int, completion: @escaping (() -> Void) = {() -> Void in }) throws -> Int {
        let i=removeTaskNoDelete(at)
        if i<0 {
            return i
        }
        let r=deleteTask(i, completion: completion)
        return r
    }
    
    
    //

    var permissionsRequested=false
    func getPermissions (completion: @escaping (() -> Void) = {() -> Void in }) {
        self.permissionsRequested=false;
        let permissionCompletion={() -> Void in
            if self.askedPermission4Reminders && self.askedPermission4Events {
                self.permissionsRequested=true
                completion()
            }
        }
        //Reminders
        askPermissions4Reeminders (completion: permissionCompletion)
        //Events Calendars
        askPermissions4Events (completion: permissionCompletion)
    }
    var askedPermission4Reminders=false
    var allowedReminders=false
    func askPermissions4Reeminders (completion: @escaping (() -> Void) = {() -> Void in }) {
        self.askedPermission4Reminders=false
        self.allowedReminders=false
        self.eventStore.requestAccess(to: EKEntityType.reminder, completion:  { (granted: Bool, error: Error?) -> () in
            
            if (error != nil) {
                _=self.setErrorMessage("error requesting permission for reminders")
                return
            }
            
            if granted{
                _=self.setNoError()
                self.message="reminders access granted"
                self.askedPermission4Reminders=true
                self.allowedReminders=true
                completion()
            }else{
                self.askedPermission4Reminders=true
                _=self.setErrorMessage("The app is not permitted to access reminders, make sure to grant permission in the settings and try again")
            }
        })
    }
    var askedPermission4Events=false
    var allowedEvents=false
    func askPermissions4Events (completion: @escaping (() -> Void) = {() -> Void in }) {
        self.askedPermission4Events=false
        self.allowedEvents=false
        self.eventStore.requestAccess(to: EKEntityType.event, completion:  { (granted: Bool, error: Error?) -> () in
            
            if (error != nil) {
                _=self.setErrorMessage("error requesting permission for events")
                return
            }
            
            if granted{
                _=self.setNoError()
                self.message="events access granted"
                self.askedPermission4Events=true
                self.allowedEvents=true
                completion()
            }else{
                self.askedPermission4Events=true
                _=self.setErrorMessage("The app is not permitted to access events, make sure to grant permission in the settings and try again")
            }
        })
    }
    
    
    
    func getReminders (completion: @escaping (() -> Void) = {() -> Void in }) {
        // 1
        self.eventStore = EKEventStore()
        self.reminders = [EKReminder]()
        let remindersCompletion = completion
        
        // will crash if file: Info.plist
        // does not contain key: NSRemindersUsageDescription
        // and a string for the description of the use
        
        self.eventStore.requestAccess(to: EKEntityType.reminder, completion:  { (granted: Bool, error: Error?) -> () in
            
            if (error != nil) {
                self.remindersLoaded=false
                _=self.setErrorMessage("error requesting permission")
                //print(error.debugDescription)
                //self.testData=["reminders error"]
                remindersCompletion()
                return
            }
            
            if granted{
                // 2
                _=self.setNoError()
                self.message="retrieving reminders"
                self.remindersLoaded=false
                self.reminderSelected = -1
                let predicate = self.eventStore.predicateForReminders(in: nil)
                
                self.eventStore.fetchReminders(matching: predicate, completion: { (reminders: [EKReminder]?) -> Void in
                    
                    //self.reminders = reminders
                    //self.reminders = reminders?.filter({$0.title.contains(self.calendarMarker)})
                    //-self.reminders = reminders?.filter({Task2Cal.containsMarker($0.title)})
                    //dispatch_async(dispatch_get_main_queue()) {
                    //    self.tableView.reloadData()
                    //}
                    self.reminders = (reminders?.filter({self.containsMarker($0.title)}))!
                    self.remindersLoaded=true
                    _=self.setNoError()
                    remindersCompletion()
                })
            }else{
                _=self.setErrorMessage("The app is not permitted to access reminders, make sure to grant permission in the settings and try again")
                //self.testData=["no permission to reminders"]
                self.remindersLoaded=false
                remindersCompletion()
            }
        })
    }
    
    
    var calendarDefault:EKCalendar!
    func getDefaultCalendar () -> EKCalendar {
        calendarDefault=self.eventStore.defaultCalendarForNewEvents
        return calendarDefault
    }
    
    /*
     var allFiles=true
     var remindersFiles: [EKCalendar]!
     var remindersFileDefault: EKCalendar!
     var remindersFile: EKCalendar!
     func getRemindersFiles () -> [EKCalendar]? {
     remindersFiles=self.eventStore.calendars(for: EKEntityType.reminder)
     remindersFileDefault=self.eventStore.defaultCalendarForNewReminders()
     reminder.calendar=remindersFile
     reminder.l
     self.eventStore.save(reminder, commit: true)
     return remindersFiles
     }
     
     var allLists=true
     var remindersLists
     var remindersList
     func getRemindersList (remindersFile: String) {
     self.remindersFile=self.eventStore.calendar(withIdentifier: remindersFile)
     remindersLists=self.remindersFile.
     remindersFiles=self.eventStore..calendars(for: EKEntityType.)
     
     let predicate = self.eventStore.predicateForReminders(in: nil)
     predicate.
     self.eventStore.fetchReminders(matching: predicate, completion: { (reminders: [EKReminder]?) -> Void in
     
     }
     */
    
    //
    
    //static let calendarMarker=" [Task2Cal]"
    
    func containsMarker (_ text: String!) -> Bool {
        if text == nil {
            return false
        }
        return text.contains(calendarMarker)
    }
    func endsWithMarker (_ text: String!) -> Bool {
        if text == nil {
            return false
        }
        let lastFrom = text.count - calendarMarker.count
        if lastFrom < 0 {
            // text is shorter than calendarMarker
            return false
        }
        let indexFrom=text.index(text.startIndex, offsetBy: lastFrom)
        //let toCompare=text.substring(from: indexFrom)
        let toCompare=text[indexFrom...]
        return toCompare == calendarMarker
    }
    func addMarker (_ text: String) -> String {
        if endsWithMarker(text) {
            return text
        }
        return text+calendarMarker
    }
    func removeMarker (_ text: String) -> String {
        if !endsWithMarker(text) {
            return text
        }
        let lastFrom = text.count - calendarMarker.count
        let indexFrom=text.index(text.startIndex, offsetBy: lastFrom)
        //return text.substring(with: text.startIndex..<indexFrom)
        return String(text[text.startIndex..<indexFrom])
    }
    
    
    //
    
    var calendarsEvents:[EKCalendar]=[]
    var calendarsReminders:[EKCalendar]=[]
    
    func getCalendars () {
        // must have access to calendars
        self.eventStore.requestAccess(to: EKEntityType.event, completion:  { (granted: Bool, error: Error?) -> () in
            
            if (error != nil) {
                _=self.setErrorMessage("error requesting permission for calendars")
                return
            }
            
            if granted{
                // 2
                self.calendarsEvents = self.eventStore.calendars(for: EKEntityType.event)
                self.calendarsReminders = self.eventStore.calendars(for: EKEntityType.reminder)
                _=self.setNoError()
            }else{
                _=self.setErrorMessage("The app is not permitted to access calendars, make sure to grant permission in the settings and try again")
            }
        })
    }
    
    //
    
    var appointments:[EKEvent]=[]
    var appointmentsLoaded=false
    
    func appointmentDuration (_ appointment:EKEvent) -> DateInterval {
        var duration = DateInterval()
        duration.start=appointment.startDate
        duration.end=appointment.endDate
        return duration
    }
    
    //let calendar=Calendar.current
    func durationHours (_ appointment:EKEvent) -> Float {
        var hours:Float=0

        /*
        //let yearMonthDayHourMinuteSecond: Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day, Calendar.Component.hour, Calendar.Component.minute, Calendar.Component.second]
        let daysHourMinuteSecond: Set<Calendar.Component> = [Calendar.Component.day, Calendar.Component.hour, Calendar.Component.minute, Calendar.Component.second]
        let difference=Calendar.current.dateComponents(daysHourMinuteSecond, from: appointment.startDate, to: appointment.endDate)
        hours = Float(difference.hour!)
        hours = hours + Float(difference.minute!) * 60 / 100
        //hours = hours + Float(difference.second!) * 60 / 100 * 60 / 100
        hours = hours + Float(difference.day!) * 24
        //-hours = hours + Float(difference.month!) * 31 * 24
        //-hours = hours + Float(difference.year!) * 365 * 24
        */
        //let minutes: Set<Calendar.Component> = [Calendar.Component.minute]
        let difference=Calendar.current.dateComponents([Calendar.Component.minute], from: appointment.startDate, to: appointment.endDate)
        hours = Float(difference.minute! / 60)
        // % = mod
        hours = hours + Float(difference.minute! % 60) * 60 / 100

        
        return hours
    }

    
    func createCalendarAppointment (taskName:String, from:Date, to:Date) -> Bool {
        print (" create calendar appointment from reminder")
        if to < from {
            _=setErrorMessage("cannot created appointment that ends before it starts")
            return false
        }
        //create calendar appointment from reminder starting now
        let event:EKEvent=EKEvent(eventStore: eventStore)
        event.calendar=getDefaultCalendar()
        event.title=taskName
        event.startDate=from
        event.endDate=to
        // save appointment
        do {
            try eventStore.save(event, span: EKSpan.thisEvent, commit: true)
            _=setNoError()
        }catch{
            _=setErrorMessage("error creating event (appointment)")
            return false
        }
        //open the calendar appointment just created, in teh calendar app
        return true
    }

    func reportCalendarAppintentTextLine (_ appointment:EKEvent) -> String {
        let date=appointment.startDate
        let title=removeMarker(appointment.title)
        let hours=durationHours(appointment)
        let appointmentString="\(date)\t\(title)\t\(hours)"
        return appointmentString
    }
    
    func getAppointments (from:Date, to:Date, completion: @escaping (() -> Void) = {() -> Void in }) {
        // 1
        self.eventStore = EKEventStore()
        self.reminders = [EKReminder]()
        let appointmentsCompletion = completion
        
        // will crash if file: Info.plist
        // does not contain key: NSRemindersUsageDescription
        // and a string for the description of the use
        
        self.eventStore.requestAccess(to: EKEntityType.event, completion:  { (granted: Bool, error: Error?) -> () in
            
            if (error != nil) {
                self.appointmentsLoaded=false
                _=self.setErrorMessage("error requesting permission for events")
                //print(error.debugDescription)
                //self.testData=["reminders error"]
                appointmentsCompletion()
                return
            }
            
            if granted{
                // 2
                _=self.setNoError()
                self.message="retrieving appointments"
                self.remindersLoaded=false
                self.reminderSelected = -1
                // use default calendar
                //let selectedCalendars:[EKCalendar]=[self.getDefaultCalendar()]
                //let predicate = self.eventStore.predicateForEvents(withStart: from, end: to, calendars: selectedCalendars)
                let predicate = self.eventStore.predicateForEvents(withStart: from, end: to, calendars: nil)
                
                self.appointments=self.eventStore.events(matching: predicate)
                self.appointments=self.appointments.filter({self.containsMarker($0.title)})
                //self.appointments=self.appointments.sorted(by: {(a1:EKEvent, a2:EKEvent) -> Bool in return a1.startDate < a2.startDate})
                self.appointments.sort(by: {(a1:EKEvent, a2:EKEvent) -> Bool in return a1.startDate < a2.startDate})
                self.appointmentsLoaded=true
                _=self.setNoError()
                appointmentsCompletion()
                
                /*
                self.eventStore.enumerateEvents(matching: predicate, using:  { (event: EKEvent, error: Bool) -> Void in

                    if Task2Cal.containsMarker(event.title) {
                        appointments.append(contentsOf: event)
                    }
                    //self.reminders = reminders
                    //self.reminders = reminders?.filter({$0.title.contains(self.calendarMarker)})
                    //-self.reminders = reminders?.filter({Task2Cal.containsMarker($0.title)})
                    self.reminders = (reminders?.filter({Task2Cal.containsMarker($0.title)}))!
                    //dispatch_async(dispatch_get_main_queue()) {
                    //    self.tableView.reloadData()
                    //}
                    self.remindersLoaded=true
                    self.setNoError()
                    appointmentsCompletion()
                })
                */
            }else{
                _=self.setErrorMessage("The app is not permitted to access events, make sure to grant permission in the settings and try again")
                //self.testData=["no permission to reminders"]
                self.appointmentsLoaded=false
                appointmentsCompletion()
            }
        })
    }
    
    
    
    //
    
    func testDate () {
        let date = Date()
        let calendar = Calendar.current
        
        let year=calendar.component(.year, from: date)
        let month=calendar.component(.month, from: date)
        let day=calendar.component(.day, from: date)
        let weekday=calendar.component(.weekday, from: date)
        
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        print("hours = \(hour):\(minutes):\(seconds)")
    }
    
    //
    


}

/*
// String extension to use int for substring
extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return substring(from: fromIndex)
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return substring(to: toIndex)
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return substring(with: startIndex..<endIndex)
    }
}
*/


