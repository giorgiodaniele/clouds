# Rilascio di una macchina virtuale in ambiente Azure

Di seguito sono elencati, in modo ordinato e funzionale, gli oggetti necessari per il rilascio di una macchina virtuale in **:contentReference[oaicite:0]{index=0}**.

### 1. Resource Group
- Contenitore logico delle risorse
- Serve per organizzazione, gestione e controllo degli accessi
- **Non ha costi**
- Non è una risorsa computazionale, non è una risorsa di memorizzazione dato


### 2. Virtual Network (VNet)
- Rete privata virtuale (es. `10.0.0.0/16`)
- Gestisce lo spazio di indirizzamento IP
- Contiene una o più subnet
- Isola logicamente le risorse


### 3. Virtual Subnet
- Porzione della Virtual Network (es. `10.0.0.0/24`)
- Associa le risorse di rete (NIC, VM)
- Permette la segmentazione del traffico


### 4. Public IP Address
- Indirizzo IP pubblico associabile alla VM
- Può essere:
  - **Statico** - Azure consente all'utente di associare un indirizzo IP che non cambia mai; tuttavia, il costo di utilizzo dello stesso è continuo, anche quando non utilizzato;
  - **Dinamico** - Azure consente all'utente di dismettere l'utilizzo di un indirizzo IP (per risparmiare il costo operativo), ma non garantisce l'uguglianza con i valori precedenti;
- Consente l’accesso dall’esterno (Internet)

### 5. Network Interface Card (NIC)
- Interfaccia di rete della macchina virtuale
- Collega la VM a:
  - Subnet
  - Public IP
  - Network Security Group
- Gestisce traffico L2/L3

### 6. Network Security Group (NSG)
- Firewall a livello di rete
- Definisce regole di:
  - Ingresso (Inbound)
  - Uscita (Outbound)
- Filtra il traffico in base a:
  - IP
  - Porta
  - Protocollo

### 7. OS Disk
- Disco contenente il sistema operativo
- Può essere basato su:
  - Immagini standard
  - Immagini personalizzate
- Tipologie comuni:
  - HDD
  - SSD Standard
  - SSD Premium

La cancellazione della macchina virtuale comporta anche la cancellazione del disco; in caso la macchina virtuale dovesse generare dati da archiviare e mantenere nel tempo, quei dati dovranno essere scritti su un disco esterno.

### 8. Virtual Machine
- Risorsa computazionale finale
- Include:
  - CPU
  - RAM
  - OS Disk
  - NIC
- Esegue il carico applicativo


## Nomenclatura
In Azure, non è previsto uno schema rigido e ben definito per attribuire un nome a ciascuna risorsa; tuttavia, è importante definire una sintassi chiara, organica e coerente, condivisa all’interno del team o dell’organizzazione, che consenta di identificare rapidamente tipologia della risorsa, ambiente, area funzionale, localizzazione e scopo.

In questa demo, si utilizza:

```bash
<tipo-risorsa>-<applicazione>-<ambiente>-<regione>-<istanza>
```

Ad esempio, se l'applicazione è <code>demo</code> e il rilascio avviene in <code>norwayeast</code>, allora la macchina virtuale in ambiente di <code>test</code> potrebbe chiamarsi: 

```bash
vm-demo-test-norwayeast-01
```

## Tag
I tag sono metadati associati a ciascuna risorsa che consentono di attribuire a ciascuna di essa un identificatore, un termine di classificazione chiaro e preciso. Non tutte le risorse Azure possono essere munite di tag; tuttavia, per tutte quelle che possono averne uno, si suggerisce di utilizza almeno i tag <code>application</code>, <code>environment</code>, <code>team</code>, per consentire la classificazione in base alla progettualità, allo stato di avanzamento e al personale responsabile della risorse.
