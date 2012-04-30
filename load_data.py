from artichoke import Config
from ucursos import xml_to_graph
from virtuoso.endpoint import Endpoint
from virtuoso import ISQLWrapper
from testconfig import TestDefaultManager

config = Config("local_test_config.ini",
    default_manager=TestDefaultManager())

url = "http://%s:%s%s"
url %= (config.host, config.endpoint_port,
    config.endpoint_path)

endpoint = Endpoint(url)
isql = ISQLWrapper(config.host, config.user,
    config.password)
isql.execute_cmd("SPARQL CLEAR GRAPH <%s>" % config.graph)

isql.load_file("uchile_schema.ttl", config.graph)
isql.insert(config.graph, xml_to_graph("data.xml"))

