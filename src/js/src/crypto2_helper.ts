import { eventQueue } from './EventQueue';

import * as crypto2 from 'libersoft-crypto';

crypto2.addressBook.subscribe((value) => {
    eventQueue.events.push({
        type: 'crypto2.addressBook.subscribe',
        value: value
    });
});
