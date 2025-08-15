import { eventQueue } from './EventQueue';
import * as crypto2 from 'libersoft-crypto';
import { get } from 'svelte/store';

crypto2.addressBook.subscribe((value) => {
    eventQueue.events.push({
        type: 'crypto2.addressBook.subscribe',
        value: value
    });
});

export function crypto2getAddressBookItems() {
    console.log('crypto2getAddressBookItems called');
    const items = get(crypto2.addressBook);
    console.log('crypto2getAddressBookItems items:', items);
    return {
        status: 'success',
        data: items
    };
}
