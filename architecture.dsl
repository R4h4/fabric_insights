 workspace {

    model {
        dataUser = person "Data Manager" "Designs data architecture, creates scheduled reports, serves business's adhoc requests"
        analyticsUser = person "Head of Analytics" "Manages financial health, knows basic SQL, uses data to make management decisions"
        businessUser = person "Sales Manager" "Always after sales targets, manages large teams of salespeople, uses data insights to boost sales"
        
        dataSource = softwareSystem "Data Source" "External system like databases, cloud apps, enterprise apps, and streaming systems"
        dataStorage = softwareSystem "Datawarehouse (External)" "I.e. Snowflake, stores the data and provides compute over it" {
            tags storage
        }
        biSystem = softwareSystem "BI System" "3rd party BI-/analytics platform like PowerBI or Tableau"
        
        softwareSystem = softwareSystem "FSO Data Platform" "DataOps platform covering data ingestion" {
            // Define the individual containers
            webapp = container "Web Application" "Unified webinterface that allows to manage the individual pieces in one single place" "JavaScript, React" "WebBrowser" {
                tags webBrowser
            }
            apiGateway = container "API Gateway Layer" "Unified GraphQL API for user and frontend to interact with the individual services"
            ingestionService = container "Ingestion Service" "" "Airbyte, Java, Python"
            transformationService = container "Transformation Service" "API application that transforms data inside the DW using user-defined SQL models and pipelines" "dbt-core,Python"
            observabilityService = container "Observability Service" "API application that manages different types of logs and meta data. Other services send their logs via an EventBus, and API endpoints are provided to retrieve log aggregations" "Python, OpenTelemetry, ElasticSearch"
            orchestrationService = container "Orechestration Service" "API application that manages and runs DAGs" "dagster, Python"
            discoveryService = container "Data Catalog" "API application/data catalog that manages metadata of the data stored, as well as it's lineage, freshness, etc. Based on DataHub and then to be extended by data graph-based data ontology" "Python, Java, DataHub" 
            dataApiService = container "Data API Service" "Security and Translation layer between consumer and data warehouse. MVP can use cube, should get replaced by inhouse development in v2" "cube.js, Python"

            // Primary UI/webapp flow
            webapp -> apiGateway "Forwards requests to" "JSON, HTTPs"
            
            // Direct user interactions
            dataUser -> webapp "Create ingestion- and transformation pipelines using"
            analyticsUser -> webapp "Discovers available data in data catalog, creates new data models and pipelines and creates data APIs in"
            businessUser -> webapp "Discovers available data in data catalog of"
            businessUser -> biSystem "Creats, views and updates dashboards (self-service) in"
            dataUser -> apiGateway "Uses CI/CD and GitOps to manage data pipelines"

            // Things exposed via API
            apiGateway -> observabilityService "Query aggregated logs, status of data pipelines etc. from" "JSON, HTTPs"
            apiGateway -> discoveryService "Queries information about data, location and lineage from" "JSON, HTTPs"
            apiGateway -> transformationService "CRUD for data models and transformation jobs" "JSON, HTTPs"
            apiGateway -> orchestrationService "CRUD for data pipelines" "JSON, HTTPs"
            apiGateway -> ingestionService "CRUD for ingestion jobs" "JSON, HTTPs"
            apiGateway -> dataApiService "CRUD for data security and data APIs" "JSON, HTTPs"
            
            // Ingestion
            dataSource -> ingestionService "Has data extracted by"
            ingestionService -> dataStorage "Write data into"
            
            // Transformation and pipeline management
            transformationService -> dataStorage "Uses pushdown optimization to perform transformation inside of"
            
            // Monitoring, Logging and Data observability
            ingestionService -> observabilityService "Sends logs to" "JSON, Kafka" {
                tags "async"
            }
            transformationService -> observabilityService "Sends logs to" "JSON, Kafka" {
                tags "async"
            }
            orchestrationService -> observabilityService "Sends logs to" "JSON, Kafka" {
                tags "async"
            }

            // Data API
            discoveryService -> dataApiService "Updates available data schema in" {
                tags "async"
            }
            dataApiService -> dataStorage "Queryies data from"
            dataApiService -> biSystem  "Connects and provides to"

            // Scheduling Service
            orchestrationService -> ingestionService "Triggers jobs in" "JSON, HTTPs"
            orchestrationService -> transformationService "Triggers jobs in" "JSON, HTTPs"
            orchestrationService -> discoveryService "Sends information about pipelines and data to" "JSON, Kafka" {
                tags "async"
            }
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
