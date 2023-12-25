import SwiftUI

/*
 Bude mat queue, ak sa spusti ze je aktivny -> vytvori sa connect, najprv nadviaze spojenie
 ak je uspesne, spusti sa algoritmus, ktorý každé 2 sekundy aj je queue prazdne, posle status
 inak vykonava FIFO.
 
 Command bude schopny vytvorit command co urobi seriove spracovanie aj projektu -> lepsie riesenie chyb
 
 Ak sa strati connect, 3 pokusy? timing 15sekund?
*/

class RCNodeController {
    
    //Connection retries
    let retries = 3
    
    @State private var connEstablished: Bool = false
    @State private var commandQueue: [RCCommand] = []
    
    init(){
        
    }
    
    
    
}
