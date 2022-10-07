"""Entry point for running a Kedro pipeline as a Python package."""
import os
import socket
from pathlib import Path
from typing import Any, Dict, Union

from kedro.config import ConfigLoader
from kedro.framework.context import KedroContext
from pluggy import PluginManager
from pyspark import SparkConf
from pyspark.sql import SparkSession


class ProjectContext(KedroContext):
    """A subclass of KedroContext to add Spark initialisation for the pipeline."""

    def __init__(
        self,
        package_name: str,
        project_path: Union[Path, str],
        config_loader: ConfigLoader,
        hook_manager: PluginManager,
        env: str = None,
        extra_params: Dict[str, Any] = None,
    ):
        super().__init__(
            package_name, project_path, config_loader, hook_manager, env, extra_params
        )
        self.init_spark_session()

    def init_spark_session(self) -> None:
        """Initialises a SparkSession using the config
        defined in project's conf folder.
        """

        # Load the spark configuration in spark.yaml using the config loader
        parameters = self.config_loader.get("spark*", "spark*/**")
        spark_conf = SparkConf().setAll(parameters.items())

        if 'CONTAINER_IMAGE' in os.environ:
            spark_conf.set('spark.kubernetes.container.image', os.environ['CONTAINER_IMAGE'])
            spark_conf.set("spark.driver.host", socket.gethostbyname(socket.gethostname()))
            spark_conf.set('spark.kubernetes.driver.pod.name', socket.gethostname())

        # Initialise the spark session
        spark_session_conf = (
            SparkSession.builder.appName(self._package_name)
            .enableHiveSupport()
            .config(conf=spark_conf)
        )
        _spark_session = spark_session_conf.getOrCreate()
        _spark_session.sparkContext.setLogLevel("WARN")
