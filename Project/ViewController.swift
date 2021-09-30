//
//  ViewController.swift
//  BizganDorian-HW6
//  dab4567
//  Course: CS371L
//
//  Created by Dorian Bizgan on 6/22/20.
//  Copyright © 2020 Dorian Bizgan. All rights reserved.
//

import UIKit
import CoreData

let textCellIdentifier = "TextCell"

var documentList = [NSManagedObject]()

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DocumentUpdater {
    func updateDocument(text: String, documentTitle:String, documentIndex:Int) {
        documentList[documentIndex].setValue(text, forKey: "text")
        documentList[documentIndex].setValue(documentTitle, forKey: "title")
        
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newScanButton: UIButton!
    
    // complete actions when loading view
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.hidesBackButton = true
        newScanButton.layer.cornerRadius = 14
        newScanButton.layer.zPosition = 1
        documentCoreData()
        }

    // complete actions before view appears
    override func viewWillAppear(_ animated: Bool){
        tableView.reloadData()
        documentCoreData()
        }
    
    func addDocument(text:String, documentTitle:String) {
        
        // creating new core data object
        if text == ""{
            return
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let document_temp = NSEntityDescription.insertNewObject(forEntityName: "Document", into: context)
        
        // set values for new core data object
        document_temp.setValue(text, forKey: "text")
        document_temp.setValue(documentTitle, forKey: "title")
        
        // attempt to save object
        do {
            try context.save()
            documentList.append(document_temp)
        } catch {
            //if error occurs
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            abort()
        }
    }

    // collect stored CoreData info
    func getDocument() -> [NSManagedObject] {
        print("Inside Get Document")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Document")
        
        var fetchedResults: [NSManagedObject]? = nil
        
        do {
            try fetchedResults = context.fetch(request) as? [NSManagedObject]
        } catch {
            // if an error occurs
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            abort()
        }
        
        return(fetchedResults)!
    }
    
    // retrieve data from CoreData
    func documentCoreData() {
        documentList = getDocument()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documentList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a cell and fill with info from documentList
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath)
        
        let row = indexPath.row
        
        let text = documentList[row].value(forKey:"text") as? String

        // fill in lable title and details with data
        cell.textLabel?.text = documentList[row].value(forKey:"title") as? String
        cell.detailTextLabel?.numberOfLines = 3
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        cell.detailTextLabel?.text = "\t\(text ?? "")"

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath.row == 6 ? nil : indexPath
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
  
    // remove document from CoreData and from ViewCell
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext

            let index = indexPath.row

            context.delete(documentList[index] as NSManagedObject)

            let _ : NSError! = nil
            do {
                try context.save()
            } catch {
                print("Error: \(error)")
            }

            documentList.remove(at: indexPath.row) //Remove element from array
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NewDocumentSegueIdentifier",
            let destination = segue.destination as? DocumentViewController {
            destination.delegate = self
            destination.newScan = true
        }
        if segue.identifier == "DocumentSegueIdentifier",
            let destination = segue.destination as? DocumentViewController,
            let documentIndex = tableView.indexPathForSelectedRow?.row {
            destination.delegate = self
            destination.textFromPrevious = (documentList[documentIndex].value(forKey: "text") as? String)!
            destination.documentIndex = documentIndex
            destination.documentTitle = documentList[documentIndex].value(forKey: "title") as? String ?? "Untitled"
        }
    }
}

