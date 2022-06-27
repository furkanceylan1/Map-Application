//
//  ViewController.swift
//  My Travel Book
//
//  Created by Furkan Ceylan on 22.06.2022.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var placeArray : [String] = []
    var idArray : [UUID] = []
    
    var idSelected = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicked))
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Map")
        fetchRequest.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(fetchRequest)
            
            for result in results as! [NSManagedObject]{
                if let place = result.value(forKey: "place") as? String {
                    placeArray.append(place)
                }
                
                if let id = result.value(forKey: "id") as? UUID {
                    idArray.append(id)
                }
                
                tableView.reloadData()
            }
        }catch{
            print("Error")
        }
        
        navigationItem.title = "My Travel Book"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placeArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = placeArray[indexPath.row]
        return cell
    }
    
    override func viewWillAppear(_ animated: Bool) {
        placeArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Map")
        fetchRequest.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(fetchRequest)
            
            for result in results as! [NSManagedObject]{
                if let place = result.value(forKey: "place") as? String {
                    placeArray.append(place)
                }
                
                if let id = result.value(forKey: "id") as? UUID {
                    idArray.append(id)
                }
                
                tableView.reloadData()
            }
        }catch{
            print("Error")
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        idSelected = idArray[indexPath.row].uuidString
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    @objc func addButtonClicked(){
        idSelected = ""
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC"{
            let destinationVC = segue.destination as! mapViewController
            destinationVC.chooseId = idSelected
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Map")
            let uuIdString = idArray[indexPath.row].uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", uuIdString)
            
            do{
                let results = try context.fetch(fetchRequest)
                for result in results as! [NSManagedObject]{
                    context.delete(result)
                    idArray.remove(at: indexPath.row)
                    placeArray.remove(at: indexPath.row)
                    
                    tableView.reloadData()
                    do{
                        try context.save()
                    }catch{
                    }
                    
                }
            }catch{
                
            }
        }
    }


}

