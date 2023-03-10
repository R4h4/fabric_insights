#  What we are trying accomplish
#  Users can ingest Excel files (local and remote) and connect MySQL and PostgresQL databases
#  Excel files parsing can be configured (sheets, where the table starts, etc.)
#  Data is virtualized into parquet and indexed with Iceberg
#  Relational schema is stored in Ontology service
#  Graph schema is infered and can manually be adjusted, frontend visualization for data discovery
#  Query service allows for query using ontology graph, converts it into SQL and executes against the virtualized data


workspace {
    model {
        analyticsUser = person "Head of Analytics" "Manages financial health, knows basic SQL, uses data to make management decisions"

        dataSource = softwareSystem "Data Source" "External system like databases, cloud apps, enterprise apps, and streaming systems"
        
        softwareSystem = softwareSystem "FSO Fabric Insights" "Data discovery platform" {
            # Individual containers to makethe whole thing works
            webapp = container "Web application" "Unified webinterface so ingest, manage and discover data" "TypeScript, Svelte" {
                tags webBrowser
            }
            tenantService = container "Tenant Service" "Manages the different tenants in the "
            dataStorage = container "Storage Layer" "Stores ingested/virtualzed tables" "Parquet, Iceberg" {
                tags storage
            } 
            ontologyService = container "Ontology Service" "Manages metadata in a knowledge graph that can be manually edited and can be queried in near natural language" "Python, FastAPI, Neo4j, Cypher" {
                ontologyStorage = component "Ontology Storage" "Graph database that holds information about ontology" "Neo4j" {
                    tags storage
                }
                dataQueryService = component "Data Query translation Service" "Takes NLP/Graph queries, matches them with the metadata in the ontology and translates it into SQL that can be executed against the base data." "Python, FastAPI"
                
                dataQueryService -> ontologyStorage "Queries metadata from" "Cypher, HTTPs"
                dataQueryService -> dataStorage "Queries data from" "SQL, HTTPs"
            }
            ingestionService = container "Ingestion Service" "APIService that parses incoming data into data + metadata" "Python, FastAPI" {
                dataSourceAdapter = component "Data Source Adapter" "Unified interface for different adapters that connect to and load data from data sources like Excel or a MsQL Database and converts them into Parquet" "Python"
                dataStorageAdapter = component "Data Storage Adapter" "Unified interface for different adapters that store data in i.e. the internal storage layer or (later on) in cloud accounts of customers" "Python"
                ingestionLocalStorage = component "Storage" "Holds ingestion job definitions and metadata of executions" "PostgresQL" {
                    tags storage
                } 
                ingestionManager = component "Deals with incoming requests and coordinates the execution of ingestion jobs" "Python"

                # Connection to outside data source and destinations
                dataSource -> dataSourceAdapter "Has data extracted by"
                dataStorageAdapter -> dataStorage "Stores parquet files in"
                ingestionManager -> ingestionLocalStorage "Stores and retrieves job definitions and metadata in/from"
                ingestionManager -> dataSourceAdapter "Receives data in standaterized format (split in data and metadata) using"
                dataSourceAdapter -> dataStorageAdapter "Sends standaterized format data for storage to"

                ingestionManager -> ontologyService  "Sends metadata about data location and schema to" "JSON, HTTPs"
            }
            apiGateway = container "API Gateway Layer" "Unified API layer for user and frontend to interact with the individual services"

            # The api gateway acts as a proxy between the frontend and the individual backend-services
            webapp -> apiGateway "Forwards requests to" "REST, JSON, HTTPs"
            tenantService -> apiGateway "Secures endpoints and routes requests to the right service endpoints"

            # Flow of data through the system
            analyticsUser -> webapp "Uploads Excel files, create ingestion connections, edits ontology and discoveres data through" "JSON, HTTPs"
            apiGateway -> ingestionService "Sends files to, and performs CRUD on ingestion jobs with" "JSON, HTTPs"
            ingestionService -> dataStorage "Stores raw (Excel/CSV) files and processed parquet files in" "HTTPs"
            # Turn async later
            # ingestionService -> ontologyService "Sends metadata about data location and schema to" "JSON, Kafka" {
            #     tags "async"
            # }
            ingestionService -> ontologyService "Sends metadata about data location and schema to" "JSON, HTTPs"
            ingestionService -> dataSource "Connects to and extracts data from" "JSON, HTTPs"
            apiGateway -> ontologyService "View and edit ontology in and make queries against" "JSON, HTTPs"
            ontologyService -> dataStorage "Queries data from" "SQL, HTTPs"
        }
    }

    views {
        systemContext softwareSystem {
            include *
            autolayout lr
        }

        container softwareSystem {
            include *
            autolayout lr
        }


        component ontologyService {
            include *
            autolayout lr
        }


        component ingestionService {
            include *
            autolayout lr
        }

        styles {
            relationship "async" {
                dashed true
            }
            relationship "Relationship" {
                dashed false
            }
            element "webBrowser" {
                shape WebBrowser
            }
            element "storage" {
                shape Cylinder
            }
        }
        theme default
    }
}
