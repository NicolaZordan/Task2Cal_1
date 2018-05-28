import UIKit

// Global variable
var taskMgr=TaskManager()
// see details in Task2Cal

struct task {
    var name="unnamed"
    var desc="none"
}

class TaskManager: NSObject {
    
    //var task2Cal=Task2Cal()
    
    var tasks=[task]()
    
    func addTask (name:String, desc:String) {
        tasks.append(task(name: name, desc: desc))
    }
    
}
