'''
Created on Nov 7, 2011
Counts the number of forks given a queue of forks with no other third-party dependencies other than our own.
You can get the fork count of a github_repo like so:
    ForkCounter.new_with_github_api(github_api).count_forks()
@author: periksson
'''

import threading
import Queue
from GithubAPI import GithubAPI

NUMBER_OF_WORKERS = 16

class ForkCounter(object):
    
    def __init__(self, fork_queue, fork_counter_workers, initial_count=0):
        self._fork_queue = fork_queue
        self._fork_counter_workers = fork_counter_workers
        self._fork_count = initial_count
        
    def count_forks(self):
        self._start_workers()
        self._wait_fork_workers_to_finish()
        self._gather_workers_counts()
        return self._fork_count

    def _start_workers(self):
        for worker in self._fork_counter_workers:
            worker.start()
            
    def _wait_fork_workers_to_finish(self):
        self._fork_queue.join()
            
    def _gather_workers_counts(self):
        for worker in self._fork_counter_workers:
            self._fork_count += worker.get_count()
            
    @classmethod
    def new_with_github_api(cls, github_api):
        forks = github_api.forks()
        fork_queue = ForkCounter._new_fork_queue_with_forks(forks)
        workers = ForkCounter._create_fork_counter_workers(fork_queue)
        count_first_fork = 1
        return ForkCounter(fork_queue, workers, count_first_fork)
    
    @classmethod
    def _new_fork_queue_with_forks(cls, forks):
        fork_queue = Queue.Queue()
        for fork in forks:
            fork_queue.put(fork)
        return fork_queue

    @classmethod
    def _create_fork_counter_workers(cls, fork_queue):
        n_workers = NUMBER_OF_WORKERS
        return ForkCounter._create_a_number_of_fork_counter_workers(fork_queue, n_workers)

    @classmethod
    def _create_a_number_of_fork_counter_workers(cls, fork_queue, n_workers):
        workers = []
        for _ in range(n_workers):
            workers.append(ForkCounterWorker.new_with_fork_queue(fork_queue))
        return workers
    
class ForkCounterWorker(threading.Thread):
    
    def __init__(self, queue):
        threading.Thread.__init__(self)
        self._queue = queue
        self._count = 0
        
    def run(self):
        while not self._queue.empty():
            fork = self._queue.get()
            self._count += self._count_forks_in_all_depths_on_single_thread([fork])
            self._queue.task_done()
    
    def _count_forks_in_all_depths_on_single_thread(self, forks):
        total_number_of_forks = 0
        for fork in forks:
            total_number_of_forks += self._get_total_fork_count_inner_loop(fork)
        return total_number_of_forks
    
    def _get_total_fork_count_inner_loop(self, fork):
        if fork['private'] == True:
            return 0
        else:
            return self._get_total_fork_count_for_public_fork(fork)

    def _get_total_fork_count_for_public_fork(self, fork):
        github_user = fork['owner']['login']
        github_fork = fork['name']
        github_api = GithubAPI(github_user, github_fork)
        return 1 + self._count_forks_in_all_depths_on_single_thread(github_api.forks())

    def get_count(self):
        return self._count
    
    @classmethod
    def new_with_fork_queue(cls, fork_queue):
        new_worker = ForkCounterWorker(fork_queue)
        new_worker.setDaemon(True)
        return new_worker
