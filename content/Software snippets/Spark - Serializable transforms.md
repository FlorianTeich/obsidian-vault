```python
import mlflow
import subprocess
import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer
from pyspark import keyword_only
from pyspark.ml import UnaryTransformer, Pipeline, Transformer, PipelineModel
from pyspark.ml.feature import StringIndexer, VectorAssembler, OneHotEncoder, VectorSizeHint
from pyspark.ml.functions import array_to_vector, vector_to_array
from pyspark.ml.param.shared import HasInputCol, HasOutputCol, Param, Params, TypeConverters
from pyspark.ml.util import DefaultParamsReadable, DefaultParamsWritable
from pyspark.sql.functions import udf


subprocess.Popen(["mlflow","ui"])

sentences = ["This is an example sentence", "Each sentence is converted"]

model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
embeddings = model.encode(sentences)


class StringTransformer(
    Transformer,
    HasInputCol,
    HasOutputCol,
    DefaultParamsReadable,
    DefaultParamsWritable,
):
    default_value = Param(
        Params._dummy(),
        "default_value",
        "default_value",
        typeConverter=TypeConverters.toString,
    )

    @keyword_only
    def __init__(self, inputCol=None, outputCol=None, default_value=None):
        super(StringTransformer, self).__init__()
        self.default_value = Param(self, "default_value", "unknown")
        self._setDefault(default_value=[])
        kwargs = self._input_kwargs
        self.setParams(**kwargs)

    @keyword_only
    def setParams(self, inputCol=None, outputCol=None, default_value=None):
        kwargs = self._input_kwargs
        return self._set(**kwargs)

    def setDefaultValue(self, value):
        return self._set(default_value=value)

    def getDefaultValue(self):
        return self.getOrDefault(self.default_value)

    def setInputCol(self, value):
        """
        Sets the value of :py:attr:`inputCol`.
        """
        return self._set(inputCol=value)

    def setOutputCol(self, value):
        """
        Sets the value of :py:attr:`outputCol`.
        """
        return self._set(outputCol=value)

    def _transform(self, dataset):
        from pyspark.sql.functions import col, udf
        from pyspark.sql.types import StringType
        from sentence_transformers import SentenceTransformer

        out_col = self.getOutputCol()
        in_col = self.getInputCol()

        model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')

        upperCaseUDF = udf(lambda x:model.encode(str(x), show_progress_bar=False).tolist(), ArrayType(FloatType()))

        return dataset.withColumn(
            out_col,
            upperCaseUDF(col(in_col)),
        )


class ColumnCastTransformer(
        Transformer, HasInputCol, HasOutputCol,
        DefaultParamsReadable, DefaultParamsWritable):

    @keyword_only
    def __init__(self, inputCol=None, outputCol=None):
        super(ColumnCastTransformer, self).__init__()
        kwargs = self._input_kwargs
        self.setParams(**kwargs)

    @keyword_only
    def setParams(self, inputCol=None, outputCol=None):
        kwargs = self._input_kwargs
        return self._set(**kwargs)

    # Required in Spark >= 3.0
    def setInputCol(self, value):
        """
        Sets the value of :py:attr:`inputCol`.
        """
        return self._set(inputCol=value)

    # Required in Spark >= 3.0
    def setOutputCol(self, value):
        """
        Sets the value of :py:attr:`outputCol`.
        """
        return self._set(outputCol=value)

    def _transform(self, dataset):
        return dataset.withColumn("CryoSleep", dataset["CryoSleep"].cast(BooleanType())) \
            .withColumn("VIP", dataset["VIP"].cast(BooleanType())) \
            .withColumn("Age", dataset["Age"].cast(DoubleType())) \
            .withColumn("RoomService", dataset["RoomService"].cast(DoubleType())) \
            .withColumn("FoodCourt", dataset["FoodCourt"].cast(DoubleType())) \
            .withColumn("ShoppingMall", dataset["ShoppingMall"].cast(DoubleType())) \
            .withColumn("Spa", dataset["Spa"].cast(DoubleType())) \
            .withColumn("VRDeck", dataset["VRDeck"].cast(DoubleType()))


class ListToArrayTransformer(
        Transformer, HasInputCol, HasOutputCol,
        DefaultParamsReadable, DefaultParamsWritable):

    @keyword_only
    def __init__(self, inputCol=None, outputCol=None):
        super(ListToArrayTransformer, self).__init__()
        kwargs = self._input_kwargs
        self.setParams(**kwargs)

    @keyword_only
    def setParams(self, inputCol=None, outputCol=None):
        kwargs = self._input_kwargs
        return self._set(**kwargs)

    # Required in Spark >= 3.0
    def setInputCol(self, value):
        """
        Sets the value of :py:attr:`inputCol`.
        """
        return self._set(inputCol=value)

    # Required in Spark >= 3.0
    def setOutputCol(self, value):
        """
        Sets the value of :py:attr:`outputCol`.
        """
        return self._set(outputCol=value)

    def _transform(self, dataset):
        out_col = self.getOutputCol()
        return dataset.withColumn(out_col, array_to_vector(self.getInputCol()))


from pyspark.sql import SparkSession
from pyspark.sql.functions import col
from pyspark.sql.types import *


spark = SparkSession \
    .builder \
    .appName("spaceship-titanic") \
    .getOrCreate()

train = spark.read.option("header", True).csv("spaceship-titanic/train.csv") \
            .withColumn("Transported", col("Transported").cast(BooleanType()))

cct = ColumnCastTransformer()

homeplanetIndexer = StringIndexer(inputCol="HomePlanet", outputCol="HomePlanet_processed",
    stringOrderType="frequencyDesc", handleInvalid="keep")
destinationIndexer = StringIndexer(inputCol="Destination", outputCol="Destination_processed",
    stringOrderType="frequencyDesc", handleInvalid="keep")
ohe_homeplanet = OneHotEncoder().setInputCol("HomePlanet_processed").setOutputCol("HomePlanet_onehot")
ohe_destination = OneHotEncoder().setInputCol("Destination_processed").setOutputCol("Destination_onehot")

name_ = StringTransformer().setInputCol('Name').setOutputCol("Name_Processed")
cabin_ = StringTransformer().setInputCol('Cabin').setOutputCol("Cabin_Processed")

sizeHintName = VectorSizeHint(inputCol="Name_Processed_vec", size=384)
sizeHintCabin = VectorSizeHint(inputCol="Cabin_Processed_vec", size=384)

name_vec_ = ListToArrayTransformer().setInputCol('Name_Processed').setOutputCol("Name_Processed_vec")
cabin_vec_ = ListToArrayTransformer().setInputCol('Cabin_Processed').setOutputCol("Cabin_Processed_vec")

vecAssembler = VectorAssembler(handleInvalid="keep", outputCol="features")
vecAssembler.setInputCols(["Name_Processed_vec",
                           "Cabin_Processed_vec",
                           "CryoSleep",
                           "HomePlanet_onehot",
                           "Destination_onehot",
                           "Age",
                           "VIP",
                           "RoomService",
                           "FoodCourt",
                           "ShoppingMall",
                           "Spa",
                           "VRDeck",
                          ])

pipeline = Pipeline(stages=[cct, name_, cabin_, homeplanetIndexer, destinationIndexer, ohe_homeplanet, ohe_destination,
                            name_vec_, cabin_vec_, sizeHintName, sizeHintCabin, vecAssembler])
#pipeline.fit(train).transform(train).show()

try:
    mlflow.create_experiment("titanic")
except:
    pass
mlflow.set_experiment("titanic")

train = spark.read.option("header", True).csv("spaceship-titanic/train.csv") \
            .withColumn("Transported", col("Transported").cast(BooleanType()))
test = spark.read.option("header", True).csv("spaceship-titanic/test.csv")
sample_submission = spark.read.option("header", True).csv("spaceship-titanic/sample_submission.csv")

pipelineModel = PipelineModel.load("/kaggle/working/pipeline")

#!rm -rf /kaggle/working/train_data
processed_train_df = pipelineModel.transform(train)
processed_train_df.write.parquet("train_data")
#processed_train_df = spark.read.parquet("train_data")

#!rm -rf /kaggle/working/test_data
processed_test_df = pipelineModel.transform(test)
processed_test_df.write.parquet("test_data")
#processed_test_df = spark.read.parquet("test_data")

#with mlflow.start_run():
#    mlflow.spark.log_model(pipelineModel, artifact_path="pipeline")
#
#    !rm -rf /kaggle/working/train_data
#    processed_train_df.write.parquet("train_data")
#    mlflow.log_artifact("train_data", "train_data")
```
