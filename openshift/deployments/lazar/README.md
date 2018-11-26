# *lazar* predictive toxicology service

***lazar*** (lazy structure–activity relationships) is a modular framework for predictive toxicology. Similar to the read across procedure in toxicological risk assessment, lazar creates local QSAR (quantitative structure–activity relationship) models for each compound to be predicted.

### Application structure

The *lazar* application in the OpenRiskNet e-Infrastructure is based on a single Docker container. All necessary libraries and the database are in it. A distribution based on several micro services is also possible. Depending on the environment in which the application is to be installed and any specific policies, the application may be distributed to multiple Docker containers. It is obvious to use the database and the R libraries from shared containers.

## How to build the Docker Image

### Setup the Dockerfile

  A good starting point is copy the existing GitHub repository to your local computer from [here](https://github.com/gebele/lazar-rest).

### Dependencies

  Since *lazar* is created in this Docker image as a RESTful service and as a service with a graphical user interface, additional files in the repository are required for the build process. The REST service also comes with a graphical interface, the Swagger interface. It allows you to test the necessary steps for command line use of the service. Therefore the `index.html` file is required. The `start.sh` file, which is defined as the `Entrypoint` to the Docker image, launches all required processes, such as MongoDB database and Rserve to access the R libraries. It also provides shortcuts for the Swagger interface and runs a second script `test.sh` which ensures *lazar*'s flawless functionality.


### Docker images

  Available pre-build Docker images:
    [*lazar* service image with all dependencies](https://hub.docker.com/r/gebele/lazar-rest/)
    [Rserve service for communication with all necessary R packages for *lazar* service](https://hub.docker.com/r/gebele/rserve/)
    [MongoDB database](https://hub.docker.com/r/gebele/mongodb/)

## Deploying

The [`lazar-rest-template.yaml`](https://github.com/OpenRiskNet/home/blob/master/openshift/deployments/lazar/lazar-rest-template.yaml) file in this repository provides everything you need to deploy the *lazar* service in an OpenShift environment. *lazar* will then be available as REST service, including a Swagger interface for the API and as a service with its own graphical user interface (GUI). Depending on your needs, the route or the name must be adapted. The template uses a method to automatically update the service if the base Docker image of the application is changed (trigger chain). If you do not want this, this must be changed in the template. Please read the notes in this instruction: [Automatic Redeployment of ImageStreams](https://github.com/OpenRiskNet/home/blob/master/openshift/knowledge-base/automatic-redeployment-of-image-streams.md). It is also possible to stop this process in the OpenShift environment by *pause rollouts*.

## Curl examples
Following some cURL examples for a typical workflow when working with *lazar* as a REST service.

### Select an endpoint

* GET a list of available endpoints
  ```
  curl -X GET "https://lazar.prod.openrisknet.org/endpoint" -H  "accept: application/json"
  ```
  response:
  ```
  [
    "Blood Brain Barrier Penetration",
    "Carcinogenicity",
    "Mutagenicity",
    "Lowest observed adverse effect level (LOAEL)",
    "Acute toxicity",
    "Maximum Recommended Daily Dose"
  ]
  ```

* GET endpoint details
  ```
  curl -X GET "https://lazar.prod.openrisknet.org/endpoint/Mutagenicity" -H  "accept: application/json"
  ```
  will return a list of model URIs based on the selected endpoint with the name of the species.
  response:
  ```
  [
    {
      "Salmonella typhimurium":  "https://lazar.dev.openrisknet.org/model/5ae2e1cd5f1c2d0132328594"
    }
  ]
  ```

### Select a model

* GET model details
```
curl -X GET "https://lazar.prod.openrisknet.org/model/5ae2e1cd5f1c2d0132328594" -H  "accept: application/json"
```
response:
```
{
  "_id": {
    "$oid": "5ae2e1cd5f1c2d0132328594"
  },
  "created_at": "2018-04-27T08:39:41.778+00:00",
  "endpoint": "Mutagenicity",
  "model_id": {
    "$oid": "5ae2de245f1c2d013232849d"
  },
  "qmrf": {
    "group": "QMRF 4.10. Mutagenicity",
    "name": "OECD 471 Bacterial Reverse Mutation Test"
  },
  "repeated_crossvalidation_id": {
    "$oid": "5ae2e1cd5f1c2d0132328593"
  },
  "source": "http://cheminformatics.org/datasets/",
  "species": "Salmonella typhimurium",
  "unit": null,
  "updated_at": "2018-04-27T08:39:41.778+00:00"
}
```
including more details for the model
  * local QSAR model ID for this particular prediction
  * QMRF report
  * repeated crossvalidation ID
  if you are interested in the validation results you can query with this ID and GET three independent 10-fold crossvalidation IDs to inspect.
  * source of the training data

### Predict a compound

* POST compound to model for prediction
  ```
  curl -X POST "https://lazar.prod.openrisknet.org/model/5ae2e1cd5f1c2d0132328594" -H  "accept: application/json" -H  "Content-Type: application/x-www-form-urlencoded" -d "identifier=%22O%3DC1NC(%3DO)NC%3DC1%22"
  ```
  Accepted identifiers are:
  * SMILES
  * InChI

### Prediction result

  ```
  {"#\u003cOpenTox::Compound:0x000055f946661f30\u003e":
      {"id":{"$oid":"5ae2dd895f1c2d013232724b"},
      "inchi":"InChI=1S/C4H4N2O2/c7-3-1-2-5-4(8)6-3/h1-2H,(H2,5,6,7,8)",
      "smiles":"O=c1cc[nH]c(=O)[nH]1",
    "model":
      {"_id":{"$oid":"5ae2e1cd5f1c2d0132328594"},"created_at":"2018-04-27T08:39:41.778+00:00","endpoint":"Mutagenicity","model_id":{"$oid":"5ae2de245f1c2d013232849d"},"qmrf":{"group":"QMRF 4.10. Mutagenicity","name":"OECD 471 Bacterial Reverse Mutation Test"},"repeated_crossvalidation_id":{"$oid":"5ae2e1cd5f1c2d0132328593"},"source":"http://cheminformatics.org/datasets/","species":"Salmonella typhimurium","unit":null,"updated_at":"2018-04-27T08:39:41.778+00:00"},
    "prediction":
      {"warnings":[],"measurements":[],"value":"non-mutagenic","probabilities":{"mutagenic":0.06184093011795284,"non-mutagenic":0.20131696461888926},
      "neighbors":
        [{"id":"5ae2de0a5f1c2d013232783b","measurement":"mutagenic","similarity":0.125},{"id":"5ae2de0b5f1c2d013232790f","measurement":"mutagenic","similarity":0.2},{"id":"5ae2de0c5f1c2d0132327a5a","measurement":"mutagenic","similarity":0.13043478260869565},{"id":"5ae2de125f1c2d0132327e4b","measurement":"mutagenic","similarity":0.125},{"id":"5ae2de125f1c2d0132327e5a","measurement":"mutagenic","similarity":0.13043478260869565},{"id":"5ae2dd675f1c2d0132326ed7","measurement":"non-mutagenic","similarity":0.17647058823529413},{"id":"5ae2dd8b5f1c2d01323273f6","measurement":"non-mutagenic","similarity":0.15789473684210525},{"id":"5ae2dd675f1c2d0132326f07","measurement":"non-mutagenic","similarity":0.1111111111111111},{"id":"5ae2de155f1c2d0132327fa0","measurement":"non-mutagenic","similarity":0.125},{"id":"5ae2de155f1c2d0132327fad","measurement":"non-mutagenic","similarity":0.13636363636363635},{"id":"5ae2de165f1c2d013232803b","measurement":"non-mutagenic","similarity":0.13043478260869565},{"id":"5ae2de165f1c2d01323280b1","measurement":"non-mutagenic","similarity":0.125},{"id":"5ae2de175f1c2d0132328143","measurement":"non-mutagenic","similarity":0.1},{"id":"5ae2dd675f1c2d0132326e6d","measurement":"non-mutagenic","similarity":0.1111111111111111},{"id":"5ae2de1b5f1c2d0132328338","measurement":"non-mutagenic","similarity":0.1},{"id":"5ae2de1d5f1c2d013232842a","measurement":"non-mutagenic","similarity":0.13636363636363635},{"id":"5ae2de1d5f1c2d0132328435","measurement":"non-mutagenic","similarity":0.13636363636363635},{"id":"5ae2de1d5f1c2d013232843e","measurement":"non-mutagenic","similarity":0.13636363636363635},{"id":"5ae2de1d5f1c2d013232844e","measurement":"non-mutagenic","similarity":0.2631578947368421},{"id":"5ae2de1d5f1c2d0132328470","measurement":"non-mutagenic","similarity":0.23809523809523808},{"id":"5ae2de1d5f1c2d0132328478","measurement":"non-mutagenic","similarity":0.13043478260869565}],
      "prediction_feature_id":{"$oid":"5ae2de075f1c2d0132327659"}
    }}
  }
  ```
The prediction object includes first a summary of what you entered.
  * your identifier as a compound object with details
  * the selected endpoint
  * the model with details

followed by the actual result
  * result value
  * warnings (if any occur)
  * measurements (in case the compound was part of the training data for the selected model)
  * probabilities or prediction interval
  * list of neighbors with details
  * prediction feature

If you want more details about the neighbors you have to request them as substances
  ```
  curl -X GET "https://lazar.prod.openrisknet.org/substance/5ae2de155f1c2d0132327fad" -H  "accept: application/json"
  ```
response:
  ```
  {
  "compound": {
    "id": {
      "$oid": "5ae2de155f1c2d0132327fad"
    },
    "inchi": "InChI=1S/C11H16FN3O3/c1-2-3-4-5-6-13-10(17)15-7-8(12)9(16)14-11(15)18/h7H,2-6H2,1H3,(H,13,17)(H,14,16,18)",
    "smiles": "CCCCCCNC(=O)n1cc(F)c(=O)[nH]c1=O",
    "warnings": []
  }
}
```
Details about the prediction feature
  ```
  curl -X GET "https://lazar.dev.openrisknet.org/feature/5ae2de075f1c2d0132327659" -H  "accept: application/json"
  ```
response:
  ```
  {
    "URI": "https://lazar.dev.openrisknet.org/feature/5ae2de075f1c2d0132327659",
    "_id": {
      "$oid": "5ae2de075f1c2d0132327659"
    },
    "accept_values": [
      "mutagenic",
      "non-mutagenic"
    ],
    "calculated": null,
    "category": null,
    "conditions": null,
    "created_at": "2018-04-27T08:23:35.924+00:00",
    "measured": null,
    "name": "Mutagenicity",
    "source": null,
    "unit": null,
    "updated_at": "2018-04-27T08:23:35.924+00:00",
    "warnings": []
  }
  ```
<!---
## Warnings
There might occur warnings in your prediction result.

##### with regression models

```
Similarity threshold 0.2 < 0.5, prediction may be out of applicability domain.
```
For regression models *lazar* tries to create a local random forest model with a neighbor similarity threshold of 0.5. If that works we are lucky, because these predictions are as accurate as the bioassay.
If that does not work (usually because we cannot find enough neighbors for the local model) we release the criteria and try again with a similarity threshold of 0.2. These results are less accurate than those with a 0.5 threshold, but still usable (i.e. significantly better than random guessing) and you should be cautious. In order to indicate this situation we add this warning.
```
Similarity threshold 0.2 < 0.5, prediction may be out of applicability domain.
Cannot create prediction: Only one similar compound in the training set.
```
If we cannot find enough neighbors with a similarity threshold of 0.2 we are out of luck. In this case we add this warning.

```
Could not find similar substances with experimental data in the training dataset.
```
If we cannot find neighbors with a similarity threshold of 0.2 we add this warning.

```
Weighted average prediction, no prediction interval available.
R caret model creation error. Using weighted average of similar substances
```
As a fallback algorithm we use weighted average of similar substances if the random forest algorithm does not success.

```
Weighted average prediction, no prediction interval available.
Insufficient number of neighbors (2) for regression model.
Using weighted average of similar substances.
```
As a fallback algorithm we use weighted average of similar substances if the number of neighbors is less than three.
```
Weighted average prediction, no prediction interval available.
No variables for regression model.
Using weighted average of similar substances.
```
As a fallback algorithm we use weighted average of similar substances if the fingerprints for the compound are missing.

##### with classification models

```
Cannot create prediction: Only one similar compound in the training set.
```
If we can not find enough neighbors we add this warning.
--->


## Info
There might occur an info in your prediction result.

```
Substance has been excluded from neighbors, because it is identical with the query substance.
```
All information from this compound was removed from the training data before the prediction to obtain unbiased results. We exclude the query substance from the local QSAR model.

## Tests
The first time you start the application, a test is run that checks for proper functionality. If the test has been successfully completed, the application is accessible otherwise the application will be closed and the test results must be considered to look for the error.

In an OpenShift environment you go to the ***pod*** log file .

In a Docker environment you inspect the log file for your ***container***.

The test can be anytime fired from the terminal of your container and inspected as code [here](https://github.com/gebele/lazar-rest/blob/master/service-test.rb)
