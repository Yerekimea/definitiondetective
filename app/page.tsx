import Home from '../src/app/page';
import RootLayout from '../src/app/layout';

export default function Root() {
  return <RootLayout>{<Home />}</RootLayout>;
}
