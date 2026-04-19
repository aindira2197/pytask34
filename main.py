class RateLimiter:
    def __init__(self, max_requests, time_window):
        self.max_requests = max_requests
        self.time_window = time_window
        self.requests = []

    def is_allowed(self):
        current_time = time.time()
        self.requests = [request for request in self.requests if current_time - request < self.time_window]
        if len(self.requests) < self.max_requests:
            self.requests.append(current_time)
            return True
        return False

import time
import threading

class RateLimiterManager:
    def __init__(self):
        self.limiters = {}

    def get_limiter(self, key, max_requests, time_window):
        if key not in self.limiters:
            self.limiters[key] = RateLimiter(max_requests, time_window)
        return self.limiters[key]

def rate_limited(max_requests, time_window):
    def decorator(func):
        limiter = RateLimiterManager().get_limiter(func.__name__, max_requests, time_window)
        def wrapper(*args, **kwargs):
            if limiter.is_allowed():
                return func(*args, **kwargs)
            else:
                raise Exception("Rate limit exceeded")
        return wrapper
    return decorator

@rate_limited(5, 60)
def example_function():
    print("Hello, world!")

def test_rate_limiter():
    for _ in range(10):
        try:
            example_function()
        except Exception as e:
            print(e)

thread1 = threading.Thread(target=test_rate_limiter)
thread2 = threading.Thread(target=test_rate_limiter)
thread1.start()
thread2.start()
thread1.join()
thread2.join()