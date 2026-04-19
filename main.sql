CREATE TABLE RateLimit (
    id INT PRIMARY KEY,
    ip_address VARCHAR(255),
    request_count INT,
    last_request_time TIMESTAMP
);

CREATE INDEX idx_ip_address ON RateLimit(ip_address);

CREATE FUNCTION is_rate_limited(ip_address VARCHAR(255)) RETURNS BOOLEAN AS $$
DECLARE
    current_time TIMESTAMP;
    request_count INT;
BEGIN
    current_time := NOW();
    SELECT request_count INTO request_count FROM RateLimit WHERE ip_address = $1;
    IF request_count IS NULL THEN
        INSERT INTO RateLimit(ip_address, request_count, last_request_time) VALUES($1, 1, current_time);
        RETURN FALSE;
    ELSEIF current_time - last_request_time > INTERVAL '1 minute' THEN
        UPDATE RateLimit SET request_count = 1, last_request_time = current_time WHERE ip_address = $1;
        RETURN FALSE;
    ELSEIF request_count < 10 THEN
        UPDATE RateLimit SET request_count = request_count + 1 WHERE ip_address = $1;
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER rate_limit_trigger BEFORE INSERT ON RateLimit FOR EACH ROW EXECUTE PROCEDURE is_rate_limited(NEW.ip_address);

INSERT INTO RateLimit(ip_address, request_count, last_request_time) VALUES('192.168.1.1', 0, NOW());

SELECT * FROM RateLimit;

CREATE TABLE RequestLog (
    id INT PRIMARY KEY,
    ip_address VARCHAR(255),
    request_time TIMESTAMP
);

CREATE INDEX idx_ip_address ON RequestLog(ip_address);

CREATE FUNCTION log_request(ip_address VARCHAR(255)) RETURNS VOID AS $$
BEGIN
    INSERT INTO RequestLog(ip_address, request_time) VALUES($1, NOW());
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_request_trigger AFTER INSERT ON RateLimit FOR EACH ROW EXECUTE PROCEDURE log_request(NEW.ip_address);

SELECT * FROM RequestLog;

CREATE TABLE BlockedIPs (
    id INT PRIMARY KEY,
    ip_address VARCHAR(255),
    block_time TIMESTAMP
);

CREATE INDEX idx_ip_address ON BlockedIPs(ip_address);

CREATE FUNCTION block_ip(ip_address VARCHAR(255)) RETURNS VOID AS $$
BEGIN
    INSERT INTO BlockedIPs(ip_address, block_time) VALUES($1, NOW());
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER block_ip_trigger AFTER INSERT ON RateLimit FOR EACH ROW EXECUTE PROCEDURE block_ip(NEW.ip_address);

SELECT * FROM BlockedIPs;