//
//  ViewController.m
//  XPYMultiThreadDemo
//
//  Created by 项小盆友 on 2019/1/10.
//  Copyright © 2019年 xpy. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, copy) NSArray *items;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self barrierSync];
}

/**
 栅栏处理同步多任务，任务按先后顺序执行
 */
- (void)barrierSync {
    //并行队列
    //dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
    //串行队列
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(queue, ^{
        sleep(2);
        NSLog(@"task1 %@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        sleep(1);
        NSLog(@"task2 %@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        sleep(3);
        NSLog(@"task3 %@", [NSThread currentThread]);
    });
    dispatch_barrier_sync(queue, ^{
        NSLog(@"task barrier %@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        sleep(2);
        NSLog(@"task4 %@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        sleep(1);
        NSLog(@"task5 %@", [NSThread currentThread]);
    });
}

/**
 栅栏处理异步多任务，task1、task2、task3顺序不定，task4、task5顺序不定
 */
- (void)barrierAsync {
    //并行队列
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
    //串行队列:若为串行队列，任务永远按顺序执行
    //dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        NSLog(@"task1 %@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"task2 %@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"task3 %@", [NSThread currentThread]);
    });
    dispatch_barrier_async(queue, ^{
        NSLog(@"task barrier %@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"task4 %@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"task 5 %@", [NSThread currentThread]);
    });
}

/**
 GCD队列组处理多任务先执行，再进行后面任务，task1、task2、task3顺序不定，三个完成后执行task last
 */
- (void)groupQueue {
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, queue, ^{
        NSLog(@"task1 %@", [NSThread currentThread]);
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"task2 %@", [NSThread currentThread]);
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"task3 %@", [NSThread currentThread]);
    });
    dispatch_group_notify(group, queue, ^{
        NSLog(@"task last %@", [NSThread currentThread]);
    });
}


/**
 GCD组多个异步网络请求返回数据以后再进行主线程的UI操作 enter和leave要成对出现
 */
- (void)groupAsyncRequest {
    dispatch_queue_t queue = dispatch_queue_create("asyncRequest", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, queue, ^{
        dispatch_group_enter(group);
        //模拟网络请求
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(2);
            NSLog(@"task1 %@", [NSThread currentThread]);
            dispatch_group_leave(group);
        });
    });
    dispatch_group_async(group, queue, ^{
        dispatch_group_enter(group);
        //模拟网络请求
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(2);
            NSLog(@"task2 %@", [NSThread currentThread]);
            dispatch_group_leave(group);
        });
    });
    dispatch_group_async(group, queue, ^{
        dispatch_group_enter(group);
        //模拟网络请求
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(2);
            NSLog(@"task3 %@", [NSThread currentThread]);
            dispatch_group_leave(group);
        });
    });
    dispatch_group_notify(group, queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"task UI %@", [NSThread currentThread]);
        });
    });
}


/**
 GCD队列组用信号量处理多个异步网络请求
 */
- (void)semaphoreRequest {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("semaphore", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_async(group, queue, ^{
        //value表示可访问新生成总信号量个数
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        //模拟网络请求
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(2);
            NSLog(@"task1 %@", [NSThread currentThread]);
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    });
    dispatch_group_async(group, queue, ^{
        //value表示可访问新生成总信号量个数
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        //模拟网络请求
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(2);
            NSLog(@"task2 %@", [NSThread currentThread]);
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    });
    dispatch_group_async(group, queue, ^{
        //value表示可访问新生成总信号量个数
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        //模拟网络请求
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(2);
            NSLog(@"task3, %@", [NSThread currentThread]);
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    });
    dispatch_group_notify(group, queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"task UI %@", [NSThread currentThread]);
        });
    });
}


/// NSOperation同步执行任务
- (void)operationSync {
    NSBlockOperation *operation1 = [NSBlockOperation blockOperationWithBlock:^{
        sleep(3);
        NSLog(@"task1 %@", [NSThread currentThread]);
        NSLog(@"main thread:%@", [NSThread mainThread]);
    }];
    [operation1 start];
    
    NSBlockOperation *operation2 = [NSBlockOperation blockOperationWithBlock:^{
        sleep(2);
        NSLog(@"task2 %@", [NSThread currentThread]);
        NSLog(@"main thread:%@", [NSThread mainThread]);
    }];
    [operation2 start];
    
    NSBlockOperation *operation3 = [NSBlockOperation blockOperationWithBlock:^{
        sleep(1);
        NSLog(@"task3 %@", [NSThread currentThread]);
        NSLog(@"main thread:%@", [NSThread mainThread]);
    }];
    [operation3 start];
}

/// NSOperation和NSOperationQueue实现同步任务效果
- (void)operationQueueSync {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    // 设置并发数为1实现同步效果
    queue.maxConcurrentOperationCount = 1;
    NSBlockOperation *operation1 = [NSBlockOperation blockOperationWithBlock:^{
        sleep(2);
        NSLog(@"task1 %@", [NSThread currentThread]);
    }];
    NSBlockOperation *operation2 = [NSBlockOperation blockOperationWithBlock:^{
        sleep(1);
        NSLog(@"task2 %@", [NSThread currentThread]);
    }];
    NSBlockOperation *operation3 = [NSBlockOperation blockOperationWithBlock:^{
        sleep(3);
        NSLog(@"task3 %@", [NSThread currentThread]);
    }];

    [queue addOperation:operation1];
    [queue addOperation:operation2];
    [queue addOperation:operation3];
}

/// 网络请求数据返回以后再将相应队列任务加入到队列中
- (void)operationQueue {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSBlockOperation *lastOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"last task");
    }];
    NSBlockOperation *requestOperation1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task1");
    }];
    NSBlockOperation *requestOperation2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task2");
    }];
    NSBlockOperation *requestOperation3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task3");
    }];
    [lastOperation addDependency:requestOperation1];
    [lastOperation addDependency:requestOperation2];
    [lastOperation addDependency:requestOperation3];
    [queue addOperation:lastOperation];
    
    [NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:@"https://www.csdn.net"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [queue addOperation:requestOperation1];
    }];
    [NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:@"https://www.baidu.com"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [queue addOperation:requestOperation2];
    }];
    [NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:@"https://github.com"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [queue addOperation:requestOperation3];
    }];
}

//- (void)test {
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//    dispatch_group_t group = dispatch_group_create();
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_group_async(group, queue, ^{
//        dispatch_async(queue, ^{
//            sleep(1);
//            NSLog(@"模拟网络请求1");
//            dispatch_semaphore_signal(semaphore);
//        });
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//    });
//    dispatch_group_async(group, queue, ^{
//        dispatch_async(queue, ^{
//            sleep(5);
//            NSLog(@"模拟网络请求2");
//            dispatch_semaphore_signal(semaphore);
//        });
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//    });
//    dispatch_group_async(group, queue, ^{
//        dispatch_async(queue, ^{
//            sleep(3);
//            NSLog(@"模拟网络请求3");
//            dispatch_semaphore_signal(semaphore);
//        });
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//    });
//    dispatch_group_notify(group, queue, ^{
//        NSLog(@"全部网络请求完成后的操作");
//    });
//}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = self.items[indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.textLabel.numberOfLines = 0;
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0: {
            [self barrierSync];
        }
            break;
        case 1: {
            [self barrierAsync];
        }
            break;
        case 2: {
            [self groupQueue];
        }
            break;
        case 3: {
            [self groupAsyncRequest];
        }
            break;
        case 4: {
            [self semaphoreRequest];
        }
            break;
        case 5: {
            [self operationSync];
        }
            break;
        case 6: {
            [self operationQueueSync];
        }
            break;
        case 7: {
            [self operationQueue];
        }
            break;
        default:
        break;
    }
}


- (NSArray *)items {
    if (!_items) {
        _items = @[@"GCD栅栏函数处理同步任务先后顺序",
                   @"GCD栅栏函数处理异步任务先后顺序",
                   @"GCD队列组处理先完成多任务再完成后面任务",
                   @"GCD队列组用group_enter和group_leave处理多个异步网络请求",
                   @"GCD队列组用信号量处理多个异步网络请求",
                   @"NSOperation同步执行任务",
                   @"NSOperation和NSOperationQueue实现同步任务效果",
                   @"NSOperationQueue处理多个操作完成后处理最后任务"];
    }
    return _items;
}


@end
