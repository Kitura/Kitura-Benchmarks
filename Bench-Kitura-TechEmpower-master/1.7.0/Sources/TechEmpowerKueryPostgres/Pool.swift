/*
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
// Author: David Jones (djones6)
//
// Simple object pool implementation, which allows objects to be take()n and give()n back after
// they are finished with.
//
// This implementation uses a serial Dispatch queue for thread-safety, and a Dispatch semaphore
// to block if the pool is empty (with an optional timeout).
//
// The pool is FIFO: items will be taken from the head of the pool, and when given back, are 
// appended to the pool. This means that each item should be taken a similar number of times.
//
import LoggerAPI
import Dispatch
#if os(Linux)
import Glibc
#else
import Darwin
#endif

public class Pool<T> {

  // Array implementation of a pool of type T
  private var pool:[T] = []
  // A serial dispatch queue used to ensure thread safety when accessing the pool
  // (at time of writing, serial is the default, and cannot be explicitly specified)
  private let lockQueue = DispatchQueue(label: "lockQueue")
  // A generator function for items in the pool, which allows future expansion
  private let generator: () -> T
  // The maximum size of this pool
  private let limit: Int
  // The initial size of this pool
  private var capacity: Int
  // A semaphore to enable take() to block when the pool is empty
  private var semaphore: DispatchSemaphore
  // A timeout value (in nanoseconds) to wait before returning nil from a take()
  private let timeoutNs: Int64
  private let timeout: Int

  // Create a Pool containing N items. The generator function will be invoked N times to fill
  // the pool to the initial capacity. The pool will be allowed to grow later, up to a specified
  // limit. If limit is not specified, or limit <= capacity, the pool cannot grow.
  // capacity: the initial size of the pool (required)
  // limit: the maximum size of the pool
  // timeout: maximum wait (in milliseconds) to take() a resource before returning nil
  // generator: a closure that returns a new item suitable for this pool
  init(capacity: Int, limit: Int = 0, timeout: Int = 0, generator: @escaping () -> T) {
    self.capacity = capacity
    self.limit = limit
    self.timeout = timeout
    self.timeoutNs = Int64(timeout) * 1000000  // Convert ms to ns
    self.generator = generator
    self.semaphore = DispatchSemaphore(value: capacity)
    for _ in 1...capacity {
      let item:T = generator()
      pool.append(item)
    }
    Log.info("Pool.init: Pool contains \(pool.count) items, limit = \(max(capacity, limit)) items")
  }

  // Take an item from the pool. The item will not magically rejoin the pool when no longer
  // needed, so MUST later be returned to the pool with give() if it is to be reused.
  // Items can therefore be borrowed or permanently removed with this method.
  // 
  // This function will block until an item can be obtained from the pool. If all items are
  // exhausted and never returned, and no timeout was specified when creating the pool, this
  // method will block indefinitely.
  public func take() -> T? {
    var item:T!
    // Indicate that we are going to take an item from the pool. The semaphore will
    // block if there are currently no items to take, until one is returned via give()
    let ret = self.semaphore.wait(timeout: (timeout == 0 ? .distantFuture : .now() + DispatchTimeInterval.milliseconds(timeout)))
    if ret == DispatchTimeoutResult.timedOut {
      Log.warning("Pool.take: timeout waiting for resource")
      return nil
    }
    // We have permission to take an item - do so in a thread-safe way
    lockQueue.sync {
      [unowned self] in
      Log.debug("Pool.take: Pool contains \(self.pool.count) items")
      if (self.pool.count < 1) {
        Log.error("Pool.take: Pool unexpectedly empty (count = \(self.pool.count))")
        return
      }
      item = self.pool[0]
      self.pool.removeFirst()
      Log.debug("Pool.take: Pool now contains \(self.pool.count) items")
      // If we took the last item, we can choose to grow the pool
      if (self.pool.count == 0 && self.capacity < self.limit) {
        self.capacity += 1
        Log.info("Auto-growing the pool (new capacity: \(self.capacity))")
        self.give(self.generator())
      }
    }
    return item
  }

  // Give an item back to the pool. Whilst this item would normally be one that was earlier
  // take()n from the pool, a new item could be added to the pool via this method.
  public func give(_ item: T) {
    lockQueue.async {
      [unowned self] in
      self.pool.append(item)
      Log.debug("Pool.give: Pool now contains \(self.pool.count) items")
      // Signal that an item is now available
      self.semaphore.signal()
    }
  }

}
