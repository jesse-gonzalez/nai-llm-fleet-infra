import unittest

func = __import__("func")

class TestFunc(unittest.TestCase):

  def test_func_empty_request(self):
    resp, code = func.main({{"EventType":"s3:ObjectCreated:Put","Key":"documents","Records":[{"eventError":"","eventVersion":"2.0","eventSource":"aws:s3","awsRegion":"us-east-1","eventTime":"2023-10-26T17:51:15Z","eventName":"s3:ObjectCreated:Put","userIdentity":{"principalId":"milvus@ntnxlab.local"},"requestParameters":{"sourceIPAddress":"10.54.78.87"},"responseElements":{"x-amz-id-2":"110000+1227+183666+19326","x-amz-request-id":"110000+1227+183666+19326","x-ntnx-origin-endpoint":"0.0.0.0"},"s3":{"s3SchemaVersion":"1.0","configurationId":"8aba40db-e56d-476b-a55a-0876dbbc6215","OSSDomain":"objects.ntnxlab.local","bucket":{"name":"documents","ownerIdentity":{"principalId":"admin"},"arn":"arn:aws:s3:::documents"},"object":{"key":"KB14799.json","size":"3087","eTag":"6bea9bb990333994adf3613cd04bb181","sequencer":"110000+1227+183666+19326"}}}],"level":"info","msg":"","time":"2023-10-26T10:51:15-07:00"}})
    self.assertEqual(resp, '{"EventType":"s3:ObjectCreated:Put","Key":"documents","Records":[{"eventError":"","eventVersion":"2.0","eventSource":"aws:s3","awsRegion":"us-east-1","eventTime":"2023-10-26T17:51:15Z","eventName":"s3:ObjectCreated:Put","userIdentity":{"principalId":"milvus@ntnxlab.local"},"requestParameters":{"sourceIPAddress":"10.54.78.87"},"responseElements":{"x-amz-id-2":"110000+1227+183666+19326","x-amz-request-id":"110000+1227+183666+19326","x-ntnx-origin-endpoint":"0.0.0.0"},"s3":{"s3SchemaVersion":"1.0","configurationId":"8aba40db-e56d-476b-a55a-0876dbbc6215","OSSDomain":"objects.ntnxlab.local","bucket":{"name":"documents","ownerIdentity":{"principalId":"admin"},"arn":"arn:aws:s3:::documents"},"object":{"key":"KB14799.json","size":"3087","eTag":"6bea9bb990333994adf3613cd04bb181","sequencer":"110000+1227+183666+19326"}}}],"level":"info","msg":"","time":"2023-10-26T10:51:15-07:00"}')
    self.assertEqual(code, 200)

if __name__ == "__main__":
  unittest.main()
