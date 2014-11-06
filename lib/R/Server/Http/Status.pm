package R::Server::Http::Status;

sub new { return {

# 1xx: Informational (��������������):
100 => "Continue", # (������������)[1][3].
101 => "Switching Protocols", # (������������� ����������)[1][3].
102 => "Processing", # (���� ���������).
105 => "Name Not Resolved", # (��� ������� ������������� DNS-����� �������).
# 2xx: Success (�������):
200 => "OK", # (�������)[1][3].
201 => "Created", # (��������)[1][3][4].
202 => "Accepted", # (��������)[1][3].
203 => "Non-Authoritative Information", # (����������� �� �����������)[1][3].
204 => "No Content", # (���� �����������)[1][3].
205 => "Reset Content", # (��������� ����������)[1][3].
206 => "Partial Content", # (���������� ����������)[1][3].
207 => "Multi-Status", # (���������������)[5].
226 => "IM Used", # (������������� IM�).
# 3xx: Redirection (���������������):
300 => "Multiple Choices", # (���������� �������)[1][6].
301 => "Moved Permanently", # (����������� ��������)[1][6].
302 => "Moved Temporarily", # (����������� ��������)[1][6].
302 => "Found", # (��������)[6].
303 => "See Other", # (�������� ������)[1][6].
304 => "Not Modified", # (�� ����������)[1][6].
305 => "Use Proxy", # (������������� ������)[1][6].
306 => "� ���������������", # (��� ������������� ������ � ������ �������������)[6].
307 => "Temporary Redirect", # (���������� ���������������)[6].
# 4xx: Client Error (������ �������):
400 => "Bad Request", # (�������, �������� ������)[1][3][4].
401 => "Unauthorized", # (���������������)[1][3].
402 => "Payment Required", # (����������� ������)[1][3].
403 => "Forbidden", # (����������)[1][3].
404 => "Not Found", # (��� �������)[1][3].
405 => "Method Not Allowed", # (������ �� ���������������)[1][3].
406 => "Not Acceptable", # (������������)[1][3].
407 => "Proxy Authentication Required", # (����������� �������������� ������)[1][3].
408 => "Request Timeout", # (�������� ����� ���������)[1][3].
409 => "Conflict", # (���������)[1][3][4].
410 => "Gone", # (�������)[1][3].
411 => "Length Required", # (����������� �����)[1][3].
412 => "Precondition Failed", # (�������� �����)[1][3][7].
413 => "Request Entity Too Large", # (������� ������� ������� �����)[1][3].
414 => "Request-URI Too Large", # (�������������� URI ������� �������)[1][3].
415 => "Unsupported Media Type", # (����������������� ��� �������)[1][3].
416 => "Requested Range Not Satisfiable", # (�������������� �������� �� ��������)[3].
417 => "Expectation Failed", # (���������� �����������)[3].
418 => "I'm a teapot", # (�� - ������)[8].
422 => "Unprocessable Entity", # (����������������� ���������).
423 => "Locked", # (��������������).
424 => "Failed Dependency", # (�������������� ������������).
425 => "Unordered Collection", # (���������������� �����)[9].
426 => "Upgrade Required", # (����������� ����������).
428 => "Precondition Required", # (����������� �����������)[10].
429 => "Too Many Requests", # (�������� ����� ��������)[10].
431 => "Request Header Fields Too Large", # (����� ��������� ������� ������� �������)[10].
434 => "Requested host unavailable.", # (�������������� ����� �����������)[�������� �� ������ 286 ����]
449 => "Retry With", # (���������� �)[2].
451 => "Unavailable For Legal Reasons", # (����������� �� ����������� ��������)[11].
456 => "Unrecoverable Error", # (����������������� ������).
499 => "Close Before Response", # ������������ Nginx, ����� ������ ��������� ���������� �� ��������� ������.
# 5xx: Server Error (������ �������):
500 => "Internal Server Error", # (����������� ������ �������)[1][3].
501 => "Not Implemented", # (��� �����������)[1][3].
502 => "Bad Gateway", # (�������, ��������� ����)[1][3].
503 => "Service Unavailable", # (������� �����������)[1][3].
504 => "Gateway Timeout", # (����� �� ��������)[1][3].
505 => "HTTP Version Not Supported", # (������� HTTP �� ���������������)[1][3].
506 => "Variant Also Negotiates", # (�������� ���� �������� ������������)[12]
507 => "Insufficient Storage", # (������������� ���������).
508 => "Loop Detected", # (����������� ������)[13]
509 => "Bandwidth Limit Exceeded", # (���������� ���������� ������ ������).
510 => "Not Extended", # (��� ���������).
511 => "Network Authentication Required", # (���������� ������� ���������������)

}}

1;