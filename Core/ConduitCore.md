#Conduit Core

ConduitCore is the basis for all conduits and provides default controls for all conduits

---

#### 'void' ConduitCore.Initialize();

Initializes the Conduit

---

#### 'bool' ConduitCore.IsConduit();

Returns true if this is a conduit

---

#### 'bool' ConduitCore.Update();

Updates itself and it's connections and returns whether the connections have changed or not

---

#### 'bool' ConduitCore.UpdateSelf();

Updates itself without updating it's connections and returns whether the connections have changed or not

---

#### 'table' ConduitCore.GetConduitNetwork();

Returns the Entire Connection Tree for the "Conduit" Connection Type

---

#### 'table' ConduitCore.GetNetwork('String' ConnectionType);

Returns the Entire Connection Tree for the Passed In Connection Type

---

#### 'table' ConduitCore.GetConduitConnections();

Gets the Current Connections for the "Conduit" Connection Type

---

#### 'table' ConduitCore.GetConnections('String' ConnectionType);

Gets the Current Connections for the Passed In Connection Type

---

#### 'void' ConduitCore.SetSpriteUpdateFunction('function' func);

Sets the function that is called when the sprite needs to be updated

---

#### 'void' ConduitCore.AddConnectionUpdateFunction('function' func);

Adds a function to a list of functions that are called when the Conduit Connections Are Updated

---

#### 'void' ConduitCore.AddNetworkUpdateFunction('function' func);

Adds a function to a list of functions that are called when the Conduit Network is Updated

---

#### 'void' ConduitCore.AddNetworkUpdateFunction('table' connections)

Sets the Connection Points

---

#### 'void' ConduitCore.UpdateContinously('bool' bool)

Sets if the conduit should update continously or not

---

#### 'void' ConduitCore.AddConnectionType('String' ConnectionType,'Function' ConditionFunction)

Adds a Connection Type

---

#### 'void' ConduitCore.RemoveConnectionType('String' ConnectionType)

Removes a Connection Type

---

#### 'void' ConduitCore.HasConnectionType('String' ConnectionType)

Returns true if the Connection Type is added and false otherwise

---

#### 'void' ConduitCore.Uninitialize()

Uninitializes the Conduit

---