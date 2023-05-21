exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const response = event.Records[0].cf.response;

  // Process the request
  if (request.uri === "/original-path") {
    // Modify the request path
    request.uri = "/modified-path";
  }

  // Process the response
  if (response.status === "200") {
    // Modify the response headers
    response.headers["x-custom-header"] = [
      { key: "X-Custom-Header", value: "Custom Value" },
    ];
  }

  return request;
};
