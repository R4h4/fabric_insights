 workspace {

    model {
        dataUser = person "Data Manager" "Designs data architecture, creates scheduled reports, serves business's adhoc requests"
        analyticsUser = person "Head of Analytics" "Manages financial health, knows basic SQL, uses data to make management decisions"
        businessUser = person "Sales Manager" "Always after sales targets, manages large teams of salespeople, uses data insights to boost sales"
        
        dataSource = softwareSystem "Data Source" "External system like databases, cloud apps, enterprise apps, and streaming systems"
        dataStorage = softwareSystem "Datawarehouse (External)" "I.e. Snowflake, stores the data and provides compute over it" "External"
        biSystem = softwareSystem "BI System" "3rd party BI-/analytics platform like PowerBI or Tableau"
        
        softwareSystem = softwareSystem "FSO Data Platform" "DataOps platform covering data ingestion" {
            webapp = container "Web Application" "Unified webinterface that allows to manage the individual pieces in one single place" "" "Web Browser" {
                dataUser -> this "Create ingestion- and transformation pipelines using"
                analyticsUser -> this "Uses" {
                    tags "Buyer"
                }
                businessUser -> this "Discovers available data in data catalog of"
            }
            apiGateway = container "API Gateway Layer" "Unified API for user and frontend to interact with the individual services" {
                webapp -> this "Forwards requests to"
                dataUser -> this "Uses CI/CD and GitOps to manage data pipelines"
            }
            ingestionService = container "Ingestion Service" "" "Airbyte,Java,Python" {
                tags "Container,Airbyte"
                            
                this -> dataSource "Connects to and extracts data from"
                this -> dataStorage "Write data into"
            }
            transformationService = container "Transformation Service" {
                this -> dataStorage "Uses pushdown optimization to perform transformation inside of"
            }
            observabilityService = container "Observability Service" {
                ingestionService -> this "Sends logs to" {
                    tags "async"
                }
                transformationService -> this "Sends logs to"
            }
            schedulingService = container "Scheduling Service" "API application that manages and runs DAGs" "dagster, Python" {
                this -> ingestionService "Triggers jobs in"
                this -> transformationService "Triggers jobs in"
                this -> observabilityService "Sends logs and metadata to"
            }
            discoveryService = container "Data Catalog" "API application/data catalog that manages metadata of the data stored, as well as it's lineage, freshness, etc. Also contains a configurable ontology on top." "?" {
                
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
        }
        theme default
    }

}